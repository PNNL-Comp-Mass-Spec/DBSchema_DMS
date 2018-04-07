/****** Object:  StoredProcedure [dbo].[AddUpdateLocalJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateLocalJobInBroker]
/****************************************************
**
**  Desc: 
**  Create or edit analysis job directly in broker database 
**    
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   08/29/2010 grk - Initial release
**          08/31/2010 grk - reset job
**          10/06/2010 grk - check @jobParam against parameters for script
**          10/25/2010 grk - Removed creation prohibition all jobs except aggregation jobs
**          11/25/2010 mem - Added parameter @DebugMode
**          07/05/2011 mem - Now updating Tool_Version_ID when resetting job steps
**          01/09/2012 mem - Added parameter @ownerPRN
**          01/19/2012 mem - Added parameter @dataPackageID
**          02/07/2012 mem - Now updating Transfer_Folder_Path after updating T_Job_Parameters
**          03/20/2012 mem - Now calling UpdateJobParamOrgDbInfoUsingDataPkg
**          03/07/2013 mem - Now calling ResetAggregationJob to reset jobs; supports resetting a job that succeeded
**                         - No longer changing job state to 20; ResetAggregationJob will update the job state
**          04/10/2013 mem - Now passing @CallingUser to MakeLocalJobInBroker
**          07/23/2013 mem - Now calling PostLogEntry only once in the Catch block
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/08/2016 mem - Include job number in errors raised by RAISERROR
**          06/16/2016 mem - Add call to AddUpdateTransferPathsInParamsUsingDataPkg
**          11/08/2016 mem - Auto-define @ownerPRN if it is empty
**          11/10/2016 mem - Pass @callingUser to GetUserLoginWithoutDomain
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          07/21/2017 mem - Fix double logging of exceptions
**          08/01/2017 mem - Use THROW if not authorized
**          11/15/2017 mem - Call ValidateDataPackageForMACJob
**          03/07/2018 mem - Call AlterEnteredByUser
**          04/06/2018 mem - Allow updating comment, priority, and owner regardless of job state
**
*****************************************************/
(
    @job int output,
    @scriptName varchar(64),
    @datasetNum varchar(128) = 'na',
    @priority int,
    @jobParam varchar(8000),
    @comment varchar(512),
    @ownerPRN varchar(64),
    @dataPackageID int,
    @resultsFolderName varchar(128) OUTPUT,
    @mode varchar(12) = 'add', -- or 'update' or 'reset'
    @message varchar(512) output,
    @callingUser varchar(128) = '',
    @DebugMode tinyint = 0
)
AS
    Set XACT_ABORT, nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @jobParamXML XML
    Declare @logErrors tinyint = 1
    
    Set @dataPackageID = IsNull(@dataPackageID, 0)
    
    Declare @reset CHAR(1) = 'N'
    If @mode = 'reset'
    Begin 
        Set @mode = 'update'
        Set @reset = 'Y'
    END 

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateLocalJobInBroker', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;;
    End;
    
    Begin TRY

        ---------------------------------------------------
        -- does job exist
        ---------------------------------------------------
        
        Declare 
            @id INT = 0,
            @state int = 0
        --
        SELECT
            @id = Job ,
            @state = State
        FROM dbo.T_Jobs
        WHERE Job = @job
        
        If @mode = 'update' AND @id = 0
            RAISERROR ('Cannot update nonexistent job %d', 11, 2, @job)

        If @mode = 'update' AND @datasetNum <> 'Aggregation'
            RAISERROR ('Currently only aggregation jobs can be updated; cannot update %d', 11, 4, @job)
            
        ---------------------------------------------------
        -- verify parameters
        ---------------------------------------------------

        If @jobParam Is Null
            RAISERROR('Web page bug: @jobParam is null for job %d', 11, 30, @job)

        If @jobParam = ''
            RAISERROR('Web page bug: @jobParam is empty for job %d', 11, 30, @job)
        
        exec @myError = VerifyJobParameters @jobParam, @scriptName, @message output
        If @myError > 0
        Begin
            Set @message = 'Error message for job ' + Cast(@job as varchar(9)) + ' from VerifyJobParameters: ' + @message
            RAISERROR(@message, 11, @myError)
        End
        
        If IsNull(@ownerPRN, '') = ''
        Begin
            -- Auto-define the owner
            Set @ownerPRN = dbo.GetUserLoginWithoutDomain(@callingUser)
        End

        If @mode = 'add'
        Begin
            ---------------------------------------------------
            -- Is data package set up correctly for the job?
            ---------------------------------------------------
            
            Declare 
                @tool VARCHAR(64) = '',            -- PSM analysis tool used by jobs in the data package; only used by scripts 'Isobaric_Labeling' and 'MAC_iTRAQ'
                @msg VARCHAR(512) = '',                     
                @valid INT = 0

            EXEC @valid = dbo.ValidateDataPackageForMACJob
                                    @dataPackageID,
                                    @scriptName,                        
                                    @tool output,
                                    'validate', 
                                    @msg output
            
            If @valid <> 0
            Begin
                -- Change @logErrors to 0 since the error was already logged to T_Log_Entries by ValidateDataPackageForMACJob
                Set @logErrors = 0
                
                RAISERROR('%s', 11, 24, @msg)
            End
        End
        
        ---------------------------------------------------
        -- update mode 
        -- restricted to certain job states and limited to certain fields
        -- force reset of job?
        ---------------------------------------------------
        
        If @mode = 'update'
        Begin --<update>
            Declare @updateTran varchar(32) = 'Update PipelineJob'

            Begin Tran @updateTran
            
            Set @jobParamXML = CONVERT(XML, @jobParam)
            
            -- Update job and params
            --
            UPDATE   dbo.T_Jobs
            SET      Priority = @priority ,
                     Comment = @comment ,
                     Owner = @ownerPRN ,
                     DataPkgID = Case When @state IN (1, 4, 5) Then @dataPackageID Else DataPkgID End
            WHERE    Job = @job

            If @state IN (1, 4, 5) And @dataPackageID > 0
            Begin
                CREATE TABLE #PARAMS (
                    [Section] varchar(128),
                    [Name] varchar(128),
                    [Value] varchar(max)
                )

                INSERT INTO #PARAMS
                        (Name, Value, Section)
                SELECT
                        xmlNode.value('@Name', 'nvarchar(256)') [Name],
                        xmlNode.value('@Value', 'nvarchar(256)') VALUE,
                        xmlNode.value('@Section', 'nvarchar(256)') [Section]
                FROM @jobParamXML.nodes('//Param') AS R(xmlNode)

                Declare @paramsUpdated tinyint = 0

                ---------------------------------------------------
                -- If this job has a 'DataPackageID' defined, update parameters
                --     'CacheFolderPath'
                --   'transferFolderPath'
                ---------------------------------------------------
                                
                exec AddUpdateTransferPathsInParamsUsingDataPkg @dataPackageID, @paramsUpdated output, @message output
                
                If @paramsUpdated <> 0
                Begin 
                    Set @jobParamXML = ( SELECT * FROM #PARAMS AS Param FOR XML AUTO, TYPE)
                End
                
            End

            If @state IN (1, 4, 5)
            Begin
                -- Store the job parameters (as XML) in T_Job_Parameters
                --
                UPDATE   dbo.T_Job_Parameters
                SET      Parameters = @jobParamXML
                WHERE    job = @job
            
                ---------------------------------------------------
                -- Lookup the transfer folder path from the job parameters
                ---------------------------------------------------
                --
                Declare @TransferFolderPath varchar(512) = ''
            
                SELECT @TransferFolderPath = [Value]
                FROM dbo.GetJobParamTableLocal ( @Job )
                WHERE [Name] = 'transferFolderPath'
            
                If IsNull(@TransferFolderPath, '') <> ''
                Begin
                    UPDATE T_Jobs
                    SET Transfer_Folder_Path = @TransferFolderPath
                    WHERE Job = @Job
                End
            
                ---------------------------------------------------
                -- If a data package is defined, update entries for 
                -- OrganismName, LegacyFastaFileName, ProteinOptions, and ProteinCollectionList in T_Job_Parameters
                ---------------------------------------------------
                --
                If @dataPackageID > 0
                Begin
                    Exec UpdateJobParamOrgDbInfoUsingDataPkg @Job, @dataPackageID, @deleteIfInvalid=0, @message=@message output, @callingUser=@callingUser
                End
            
                If @reset = 'Y'
                Begin --<reset>
            
                    exec ResetAggregationJob @job, @InfoOnly=0, @message=@message output                            
                
                END --<reset>
            End
            Else
            Begin
                Set @message = 'Only updating priority, comment, and owner since job state is not New, Complete, or Failed'
            End

            Commit Tran @updateTran

        END --</update>
        
        ---------------------------------------------------
        -- add mode
        ---------------------------------------------------

        If @mode = 'add'
        Begin --<add>

            Set @jobParamXML = CONVERT(XML, @jobParam)
            
            If @DebugMode <> 0
                Print 'JobParamXML: ' + Convert(varchar(max), @jobParamXML)

            exec MakeLocalJobInBroker
                    @scriptName,
                    @datasetNum,
                    @priority,
                    @jobParamXML,
                    @comment,
                    @ownerPRN,
                    @dataPackageID,
                    @DebugMode,
                    @job OUTPUT,
                    @resultsFolderName OUTPUT,
                    @message output,
                    @callingUser

        END --</add>

    END TRY
    Begin CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        Set @message = IsNull(@message, 'Unknown error message')
        Set @myError = IsNull(@myError, 'Unknown error details')
        
        Declare @LogMessage varchar(4096) = @message + '; error code ' + Convert(varchar(12), @myError)
        
        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @LogMessage, 'AddUpdateLocalJobInBroker'
              
            If Len(IsNull(@callingUser, '')) > 0
            Begin
                Declare @logEntryID int

                SELECT @logEntryID = MAX(Entry_ID)
                FROM T_Log_Entries
                WHERE message = @logMessage AND
                      ABS(DATEDIFF(SECOND, posting_time, GetDate())) < 15
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Exec AlterEnteredByUser 'T_Log_Entries', 'Entry_ID', @logEntryID, @CallingUser, @EntryDateColumnName = 'posting_time'
            End
        End        
    END CATCH

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLocalJobInBroker] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateLocalJobInBroker] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateLocalJobInBroker] TO [Limited_Table_Write] AS [dbo]
GO
