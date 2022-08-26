/****** Object:  StoredProcedure [dbo].[AddUpdateLocalJobInBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateLocalJobInBroker]
/****************************************************
**
**  Desc:   Create or edit analysis job directly in broker database
**
**          Example contents of @jobParam
**            Note that element and attribute names are case sensitive (use Value= and not value=)
**            Default parameters for each job script are defined in the Parameters column of table T_Scripts
**
**          <Param Section="JobParameters" Name="CreateMzMLFiles" Value="False" />
**          <Param Section="JobParameters" Name="CacheFolderRootPath" Value="\\protoapps\MaxQuant_Staging" />
**          <Param Section="JobParameters" Name="DatasetNum" Value="Aggregation" />
**          <Param Section="PeptideSearch" Name="ParamFileName" Value="MaxQuant_Tryp_Stat_CysAlk_Dyn_MetOx_NTermAcet_20ppmParTol.xml" />
**          <Param Section="PeptideSearch" Name="ParamFileStoragePath" Value="\\gigasax\DMS_Parameter_Files\MaxQuant" />
**          <Param Section="PeptideSearch" Name="OrganismName" Value="Homo_Sapiens" />
**          <Param Section="PeptideSearch" Name="ProteinCollectionList" Value="TBD" />
**          <Param Section="PeptideSearch" Name="ProteinOptions" Value="seq_direction=forward,filetype=fasta" />
**          <Param Section="PeptideSearch" Name="LegacyFastaFileName" Value="na" />
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   08/29/2010 grk - Initial release
**          08/31/2010 grk - reset job
**          10/06/2010 grk - Check @jobParam against parameters for script
**          10/25/2010 grk - Removed creation prohibition all jobs except aggregation jobs
**          11/25/2010 mem - Added parameter @debugMode
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
**          01/21/2021 mem - Log @jobParam to T_Log_Entries when @debugMode is 2
**          03/10/2021 mem - Make @jobParam an input/output variable when calling VerifyJobParameters
**                         - Send @dataPackageID and @debugMode to VerifyJobParameters
**          03/15/2021 mem - Fix bug in the Catch block that changed @myError
**                         - If VerifyJobParameters returns an error, return the error message in @message
**          01/31/2022 mem - Add more print statements to aid debugging
**          04/11/2022 mem - Use varchar(4000) when populating temp table #PARAMS using @jobParamXML
**          07/01/2022 mem - Update parameter names in comments
**          08/25/2022 mem - Use new column name in T_Log_Entries
**
*****************************************************/
(
    @job int output,
    @scriptName varchar(64),
    @datasetNum varchar(128) = 'na',
    @priority int,
    @jobParam varchar(8000),             -- XML (as text)
    @comment varchar(512),
    @ownerPRN varchar(64),
    @dataPackageID int,
    @resultsFolderName varchar(128) OUTPUT,
    @mode varchar(12) = 'add',          -- or 'update' or 'reset' or 'previewAdd'
    @message varchar(512) output,
    @callingUser varchar(128) = '',
    @debugMode tinyint = 0              -- Set to 1 to print debug messages (the new job will not actually be created); set to 2 to log debug messages in T_Log_Entries
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @jobParamXML XML
    Declare @logErrors tinyint = 1
    Declare @result int = 0

    Declare @tool varchar(64) = ''
    Declare @msg varchar(512) = ''

    Set @dataPackageID = IsNull(@dataPackageID, 0)

    Declare @reset CHAR(1) = 'N'
    If @mode = 'reset'
    Begin
        Set @mode = 'update'
        Set @reset = 'Y'
    End

    If @mode = 'previewAdd' AND @debugMode= 0
    Begin
        Set @debugMode = 1
    End

    If @debugMode > 0
    Begin
        Print ''
        Print '[AddUpdateLocalJobInBroker]'
        print @jobParam
    End

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateLocalJobInBroker', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin TRY

        ---------------------------------------------------
        -- does job exist
        ---------------------------------------------------

        Declare
            @id int = 0,
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
        -- Verify parameters
        ---------------------------------------------------

        If @jobParam Is Null
            RAISERROR('Web page bug: @jobParam is null for job %d', 11, 30, @job)

        If @jobParam = ''
            RAISERROR('Web page bug: @jobParam is empty for job %d', 11, 30, @job)

        -- Uncomment to log the job parameters to T_Log_Entries
        -- exec PostLogEntry 'Debug', @jobParam, 'AddUpdateLocalJobInBroker'
        -- goto done

        exec @myError = VerifyJobParameters @jobParam output, @scriptName, @dataPackageID, @msg output, @debugMode

        If @myError > 0
        Begin
            Set @message = 'Error from VerifyJobParameters'
            If @job > 0
            Begin
                Set @message = @message + ' (Job ' + Cast(@job as varchar(9)) + ')'
            End

            Set @message = @message + ': ' + @msg
            print @message

            RAISERROR(@message, 11, @myError)
        End

        If IsNull(@ownerPRN, '') = ''
        Begin
            -- Auto-define the owner
            Set @ownerPRN = dbo.GetUserLoginWithoutDomain(@callingUser)
        End

        If @mode in ('add', 'previewAdd')
        Begin
            ---------------------------------------------------
            -- Is data package set up correctly for the job?
            ---------------------------------------------------

            -- Validate scripts 'Isobaric_Labeling' and 'MAC_iTRAQ'
            EXEC @result = dbo.ValidateDataPackageForMACJob
                                    @dataPackageID,
                                    @scriptName,
                                    @tool output,
                                    'validate',
                                    @msg output

            If @result <> 0
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
                    [Value] varchar(4000)
                )

                INSERT INTO #PARAMS
                        (Section, Name, Value)
                SELECT
                        xmlNode.value('@Section', 'varchar(128)') [Section],
                        xmlNode.value('@Name', 'varchar(128)') [Name],
                        xmlNode.value('@Value', 'varchar(4000)') [Value]
                FROM @jobParamXML.nodes('//Param') AS R(xmlNode)

                Declare @paramsUpdated tinyint = 0

                ---------------------------------------------------
                -- If this job has a 'DataPackageID' defined, update parameters
                --   'CacheFolderPath'
                --   'transferFolderPath'
                --   'DataPackagePath'
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

        If @mode in ('add', 'previewAdd')
        Begin --<add>

            Set @jobParamXML = CONVERT(XML, @jobParam)

            If @debugMode <> 0
            Begin
                Print ''
                Print 'JobParamXML: ' + Convert(varchar(max), @jobParamXML)
                If @debugMode > 1
                Begin
                    EXEC PostLogEntry 'Debug', @jobParam, 'AddUpdateLocalJobInBroker'
                End
            End

            exec MakeLocalJobInBroker
                    @scriptName,
                    @datasetNum,
                    @priority,
                    @jobParamXML,
                    @comment,
                    @ownerPRN,
                    @dataPackageID,
                    @debugMode,
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

        Declare @logMessage varchar(4096) = @message + '; error code ' + Convert(varchar(12), @myError)

        Print 'Error caught: ' + @logMessage

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @logMessage, 'AddUpdateLocalJobInBroker'

            If Len(IsNull(@callingUser, '')) > 0
            Begin
                Declare @logEntryID int

                SELECT @logEntryID = MAX(Entry_ID)
                FROM T_Log_Entries
                WHERE message = @logMessage AND
                      ABS(DATEDIFF(SECOND, Entered, GetDate())) < 15
                --
                SELECT @myRowCount = @@rowcount

                If @myRowCount > 0
                    Exec AlterEnteredByUser 'T_Log_Entries', 'Entry_ID', @logEntryID, @CallingUser, @EntryDateColumnName = 'Entered'
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
