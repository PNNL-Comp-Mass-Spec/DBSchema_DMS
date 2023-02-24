/****** Object:  StoredProcedure [dbo].[BackfillPipelineJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[BackfillPipelineJobs]
/****************************************************
**
**  Desc:
**      Creates jobs in DMS5 for jobs that were originally
**      created in the DMS_Pipeline database
**
**  Return values: 0 if no error; otherwise error code
**
**  Auth:   mem
**  Date:   01/12/2012
**          04/10/2013 mem - Now looking up the Data Package ID using S_V_Pipeline_Jobs_Backfill
**          01/02/2014 mem - Added support for PeptideAtlas staging jobs
**          02/27/2014 mem - Now truncating dataset name to 90 characters if too long
**          02/23/2016 mem - Add set XACT_ABORT on
**          01/31/2018 mem - Truncate dataset name at 80 characters if too long
**          07/25/2018 mem - Replace brackets with underscores
**          09/15/2020 mem - Use 'https://dms2.pnl.gov/' instead of http://
**          03/09/2021 mem - Auto change script MaxQuant_DataPkg to MaxQuant
**          03/10/2021 mem - Add argument @startJob
**          03/31/2021 mem - Expand OrganismDBName to varchar(128)
**          05/26/2021 mem - Expand @message to varchar(1024)
**          07/06/2021 mem - Extract parameter file name, protein collection list, and legacy FASTA file name from job parameters
**          08/26/2021 mem - Auto change script MSFragger_DataPkg to MSFragger
**          07/01/2022 mem - Use new parameter name for parameter file when querying V_Pipeline_Job_Parameters
**          07/29/2022 mem - Settings file names can no longer be null
**          10/04/2022 mem - Assure that auto-generated dataset names only contain alphanumeric characters (plus underscore or dash)
**          02/06/2023 bcg - Update column names from views
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @jobsToProcess int = 0,                    -- Set to a positive number to process a finite number of jobs
    @startJob int = 0,                         -- Set to a positive number to start with the given job number (useful if we know that a job was just created in the Pipeline database)
    @message varchar(1024) = '' OUTPUT
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @job int
    Declare @priority int
    Declare @script varchar(64)
    Declare @state int
    Declare @dataset varchar(255)
    Declare @results_Folder_Name varchar(128)
    Declare @imported datetime
    Declare @start datetime
    Declare @finish datetime
    Declare @transferFolderPath varchar(512)
    Declare @comment varchar(512)
    Declare @owner varchar(64)
    Declare @processingTimeMinutes real

    Declare @continue tinyint
    Declare @jobsProcessed int = 0
    Declare @peptideAtlasStagingTask tinyint = 0

    Declare @analysisToolID int
    Declare @organismID Int

    Declare @parameterFileName varchar(255)
    Declare @proteinCollectionList varchar(2000)
    Declare @legacyFastaFileName varchar(128)

    Declare @datasetID int
    Declare @datasetComment varchar(128)
    Declare @jobStr varchar(12)

    Declare @dataPackageID int
    Declare @dataPackageName varchar(128)
    Declare @dataPackageFolder varchar(256)
    Declare @storagePathRelative varchar(256)

    Declare @mode varchar(12)
    Declare @msg varchar(256)

    Declare @validCh varchar(255)
    Declare @position int
    Declare @numCh int
    Declare @ch char(1)
    Declare @cleanName varchar(255)

    Declare @callingProcName varchar(128)
    Declare @currentLocation varchar(128)
    Set @currentLocation = 'Start'


    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = Coalesce(@infoOnly, 1)
    Set @jobsToProcess = Coalesce(@jobsToProcess, 0)
    Set @message = ''


    ---------------------------------------------------
    -- Create a temporary table to hold the job details
    ---------------------------------------------------

    CREATE TABLE #Tmp_Job_Backfill_Details (
        DataPackageID int NULL,
        Job int NOT NULL,
        BatchID int NULL,
        Priority int NOT NULL,
        Created datetime NOT NULL,
        Start datetime NULL,
        Finish datetime NULL,
        AnalysisToolID int NOT NULL,
        ParamFileName varchar(255) NOT NULL,
        SettingsFileName varchar(255) NOT NULL,
        OrganismDBName varchar(128) NOT NULL,
        OrganismID int NOT NULL,
        DatasetID int NOT NULL,
        Comment varchar(512) NULL,
        Owner varchar(32) NULL,
        StateID int NOT NULL,
        AssignedProcessorName varchar(64) NULL,
        ResultsFolderName varchar(128) NULL,
        ProteinCollectionList varchar(2000) NULL,
        ProteinOptionsList varchar(256) NOT NULL,
        RequestID int NOT NULL,
        PropagationMode smallint NOT NULL,
        ProcessingTimeMinutes real NULL,
        Purged tinyint NOT NULL
    )

    CREATE CLUSTERED INDEX #IX_Tmp_Job_Backfill_Details ON #Tmp_Job_Backfill_Details (Job)


    If @infoOnly > 0
    Begin
        -- Preview all of the jobs that will be backfilled
        SELECT PJ.Job,
               PJ.Priority,
               PJ.Script,
               PJ.State,
               PJ.Dataset,
               PJ.Results_Folder_Name,
               PJ.Imported,
               PJ.Start,
               PJ.Finish,
               PJ.Transfer_Folder_Path,
               PJ.[Comment],
               PJ.Owner,
               PJ.Processing_Time_Minutes,
               PJ.Data_Pkg_ID
        FROM S_V_Pipeline_Jobs_Backfill PJ
             LEFT OUTER JOIN T_Analysis_Job J
               ON PJ.Job = J.AJ_jobID
        WHERE J.AJ_JobID IS NULL
        ORDER BY PJ.Job
        --
        Select @myRowCount = @@rowCount, @myError = @@error
    End

    ---------------------------------------------------
    -- Process each job present in S_V_Pipeline_Jobs_Backfill that is not present in T_Analysis_Job
    ---------------------------------------------------

    Set @job = @startJob - 1
    Set @continue = 1
    While @continue <> 0
    Begin -- <a>

        SELECT TOP 1 @job = PJ.Job,
                     @priority = PJ.Priority,
                     @script = PJ.Script,
                     @state = PJ.State,
                     @dataset = PJ.Dataset,
                     @results_Folder_Name = PJ.Results_Folder_Name,
                     @imported = PJ.Imported,
                     @start = PJ.Start,
                     @finish = PJ.Finish,
                     @transferFolderPath = PJ.Transfer_Folder_Path,
                     @comment = PJ.[Comment],
                     @owner = PJ.Owner,
                     @processingTimeMinutes = PJ.Processing_Time_Minutes,
                     @dataPackageID = PJ.Data_Pkg_ID
        FROM S_V_Pipeline_Jobs_Backfill PJ
             LEFT OUTER JOIN T_Analysis_Job J
               ON PJ.Job = J.AJ_jobID
        WHERE PJ.Job > @job AND
              J.AJ_JobID IS NULL
        ORDER BY PJ.Job
        --
        Select @myRowCount = @@rowCount, @myError = @@error

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin -- <b>

            Set @jobStr = Convert(varchar(12), @job)

            BEGIN TRY

                Set @currentLocation = 'Validate settings required to backfill job ' + @jobStr

                ---------------------------------------------------
                -- Lookup AnalysisToolID for @script
                ---------------------------------------------------
                --
                Set @analysisToolID = -1
                If @script Like 'MaxQuant[_]%'
                Begin
                    Set @script = 'MaxQuant'
                End

                If @script Like 'MSFragger[_]%'
                Begin
                    Set @script = 'MSFragger'
                End

                SELECT @analysisToolID = AJT_toolID
                FROM T_Analysis_Tool
                WHERE (AJT_toolName = @script)

                If @analysisToolID < 0
                Begin
                    Set @message = 'Script not found in T_Analysis_Tool: ' + @script + '; unable to backfill DMS Pipeline job ' + @jobStr

                    If @infoOnly > 0
                        print @message
                    Else
                        Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'

                    Goto NextJob
                End

                If @script = 'PeptideAtlas'
                    Set @peptideAtlasStagingTask = 1
                Else
                    Set @peptideAtlasStagingTask = 0

                ---------------------------------------------------
                -- Lookup OrganismID for organism 'None'
                ---------------------------------------------------
                --
                Set @organismID = -1

                SELECT @organismID = Organism_ID
                FROM T_Organisms
                WHERE (OG_name = 'None')

                If @organismID < 0
                Begin
                    Set @message = 'Organism "None" not found in T_Organisms -- this is unexpected; will set @organismID to 1'

                    If @infoOnly > 0
                        print @message
                    Else
                        Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'

                    Set @organismID = 1
                End

                ---------------------------------------------------
                -- Validate @owner; update if not valid
                ---------------------------------------------------
                --
                If Not Exists (SELECT * FROM T_Users WHERE U_PRN = Coalesce(@owner, ''))
                    Set @owner = 'H09090911'

                ---------------------------------------------------
                -- Validate @state; update if not valid
                ---------------------------------------------------
                --
                If Not Exists (SELECT * FROM T_Analysis_State_Name WHERE AJS_stateID = @state)
                Begin
                    Set @message = 'State ' + Convert(varchar(12), @state) + 'not found in T_Analysis_State_Name -- this is unexpected; will set @state to 4'

                    If @infoOnly > 0
                        print @message
                    Else
                        Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'

                    Set @state = 4
                End

                ------------------------------------------------
                -- Lookup parameter file name and protein collection, if defined
                ------------------------------------------------
                --
                SELECT @parameterFileName = Param_Value
                FROM S_V_Pipeline_Job_Parameters
                WHERE job = 1914830 AND
                      Param_Name = 'ParamFileName'

                SELECT @proteinCollectionList = Param_Value
                FROM S_V_Pipeline_Job_Parameters
                WHERE job = 1914830 AND
                      Param_Name = 'ProteinCollectionList'

                SELECT @legacyFastaFileName = Param_Value
                FROM S_V_Pipeline_Job_Parameters
                WHERE job = 1914830 AND
                      Param_Name = 'LegacyFastaFileName'

                If Coalesce(@parameterFileName, '') = ''
                    Set @parameterFileName = 'na'

                If Coalesce(@proteinCollectionList, '') = ''
                    Set @proteinCollectionList = 'na'

                If Coalesce(@legacyFastaFileName, '') = ''
                    Set @legacyFastaFileName = 'na'

                ------------------------------------------------
                -- Check whether the dataset exists if it is not 'Aggregation'
                ------------------------------------------------
                --
                Set @datasetID = -1
                Set @datasetComment = ''

                If Coalesce(@dataset, 'Aggregation') <> 'Aggregation'
                Begin

                    SELECT @datasetID = Dataset_ID
                    FROM T_Dataset
                    WHERE Dataset_Num = @dataset
                    --
                    Select @myRowCount = @@rowCount, @myError = @@error

                END

                If @datasetID < 0
                Begin -- <c>
                    ------------------------------------------------
                    -- Dataset does not exist; auto-define the dataset to associate with this job
                    -- First lookup the data package ID associated with this job
                    ------------------------------------------------

                    Set @currentLocation = 'Auto-define the dataset to associate with job ' + @jobStr

                    If @dataPackageID <= 0
                    Begin -- <d1>
                        ------------------------------------------------
                        -- Job doesn't have a data package ID
                        -- Simply set @dataset to DP_Aggregation
                        ------------------------------------------------
                        Set @dataset = 'DP_Aggregation'

                    End -- </d1>
                    Else
                    Begin -- <d2>

                        ------------------------------------------------
                        -- Lookup the Data Package name for @dataPackageID
                        ------------------------------------------------

                        Set @dataPackageName = ''
                        Set @dataPackageFolder = ''
                        Set @storagePathRelative = ''

                        SELECT @dataPackageName = [Name],
                               @dataPackageFolder = Package_File_Folder,
                               @storagePathRelative = Storage_Path_Relative
                        FROM S_V_Data_Package_Export
                        WHERE ID = @dataPackageID
                        --
                        Select @myRowCount = @@rowCount, @myError = @@error

                        If @myRowCount = 0 Or Coalesce(@dataPackageFolder, '') = ''
                        Begin
                            -- Data Package not found (or Package_File_Folder is not defined)
                            Set @dataset = 'DataPackage_' + Convert(varchar(12), @dataPackageID)
                        End
                        Else
                        Begin
                            -- Data Package found; base the dataset name on the data package folder name
                            Set @dataset = 'DataPackage_' + @dataPackageFolder

                            If @peptideAtlasStagingTask <> 0
                            Begin
                                Set @dataset = @dataset + '_Staging'
                            End
                        End

                        Set @datasetComment = 'https://dms2.pnl.gov/data_package/show/' + Convert(varchar(12), @dataPackageID)

                    End -- </d2>

                    If Len(@dataset) > 80
                    Begin
                        -- Truncate the dataset name to avoid triggering an error in AddUpdateDataset
                        Set @dataset = Substring(@dataset, 1, 80)
                    End

                    -- Make sure there are no invalid characters in @dataset
                    -- Dataset names can only contain letters, underscores, or dashes (see function ValidateChars)

                    Set @dataset = Replace(@dataset, ' ', '_')
                                              
                    Set @validCh = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-'
                    Set @position = 1
	                Set @numCh = Len(@dataset)
                    Set @cleanName = ''

	                WHILE @position <= @numCh
		            BEGIN
			            Set @ch = SUBSTRING(@dataset, @position, 1)

			            -- Note thate @ch will have a length of 0 if it is a space, but we replaced spaces with underscores above, so @ch should always be a valid character
			            If Len(@ch) > 0
			            Begin
				            If CHARINDEX(@ch, @validCh) = 0
					            Set @cleanName = @cleanName + '_'
                            Else
                                Set @cleanName = @cleanName + @ch
			            End
				
			            Set @position = @position + 1
		            END
	                        
                    Set @dataset = @cleanName

                    ------------------------------------------------
                    -- Now that we have constructed the name of the dataset to auto-create, see if it already exists
                    ------------------------------------------------

                    SELECT @datasetID = Dataset_ID
                    FROM T_Dataset
                    WHERE Dataset_Num = @dataset
                    --
                    Select @myRowCount = @@rowCount, @myError = @@error

                    If @myRowCount = 0
                        Set @datasetID = -1

                    If @datasetID < 0
                    Begin -- <d3>

                        ------------------------------------------------
                        -- Dataset does not exist; create it
                        ------------------------------------------------

                        Set @currentLocation = 'Call AddUpdateDataset to create dataset ' + @dataset

                        If @infoOnly > 0
                        Begin
                            Set @mode = 'check_add'
                            Print 'Check_add dataset ' + @dataset
                        End
                        Else
                            Set @mode = 'add'

                        Exec @myError = AddUpdateDataset
                                            @dataset,               -- Dataset
                                            'DMS_Pipeline_Data',    -- Experiment
                                            'MSDADMIN',             -- Operator PRN
                                            'DMS_Pipeline_Data',    -- Instrument
                                            'DataFiles',            -- Dataset Type
                                            'unknown',              -- LC Column
                                            'na',                   -- Well plate
                                            'na',                   -- Well number
                                            'none',                 -- Secondary Sep
                                            'none',                 -- Internal Standard
                                            @datasetComment,        -- Comment
                                            'Released',             -- Rating
                                            'No_Cart',              -- LC Cart
                                            '',                     -- EUS Proposal
                                            'CAP_DEV',              -- EUS Usage
                                            '',                     -- EUS Users
                                            @requestID = 0,
                                            @mode = @mode,
                                            @message = @msg output,
                                            @aggregationJobDataset = 1

                        If @myError <> 0
                        Begin
                            ------------------------------------------------
                            -- Error creating dataset
                            ------------------------------------------------

                            Set @message = 'Error creating dataset ' + @dataset + ' for DMS Pipeline job ' + @jobStr
                            If Coalesce(@msg, '') <> ''
                                Set @message = @message + ': ' + @msg

                            If @infoOnly > 0
                                Print @message
                            Else
                                Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'

                            Set @datasetID = -1
                        End
                        Else
                        Begin -- <e>
                            If @infoOnly > 0
                            Begin
                                Set @datasetID = 1
                            End
                            Else
                            Begin
                                ------------------------------------------------
                                -- Determine the DatasetID for the newly-created dataset
                                ------------------------------------------------

                                Set @currentLocation = 'Determine DatasetID for newly created dataset ' + @dataset

                                SELECT @datasetID = Dataset_ID
                                FROM T_Dataset
                                WHERE Dataset_Num = @dataset
                                --
                                Select @myRowCount = @@rowCount, @myError = @@error

                                If @myRowCount = 0
                                Begin
                                    Set @message = 'Error creating dataset ' + @dataset + ' for DMS Pipeline job ' + @jobStr + '; call to AddUpdateDataset succeeded but dataset not found in T_Dataset'
                                    Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                                    Set @datasetID = -1
                                End

                                If Coalesce(@storagePathRelative, '') <> ''
                                Begin
                                    If @peptideAtlasStagingTask <> 0
                                    Begin
                                        -- The data files will be stored at a path of the form:
                                        --   \\protoapps\PeptideAtlas_Staging\829_Organelle_Targeting_ABPP
                                        -- Need to determine the path ID

                                        Declare @peptideAtlasStagingPathID int = 0

                                        SELECT @peptideAtlasStagingPathID = SP_path_ID
                                        FROM T_Storage_Path
                                        WHERE (SP_path IN ('PeptideAtlas_Staging', 'PeptideAtlas_Staging\'))

                                        If Coalesce(@peptideAtlasStagingPathID, 0) > 0
                                        Begin
                                            UPDATE T_Dataset
                                            SET DS_Storage_Path_ID = @peptideAtlasStagingPathID
                                            WHERE Dataset_ID = @datasetID

                                            Set @storagePathRelative = @dataPackageFolder
                                        End
                                    End

                                    -- Update the Dataset Folder for the newly-created dataset
                                    UPDATE T_Dataset
                                    SET DS_folder_name = @storagePathRelative
                                    WHERE Dataset_ID = @datasetID
                                End

                            End

                        End -- </e>

                    End -- </d3>

                    If @datasetID > 0
                    Begin -- <d4>

                        ------------------------------------------------
                        -- Dataset is now defined for job to backfill
                        -- Add a new row to #Tmp_Job_Backfill_Details
                        ------------------------------------------------

                        Set @currentLocation = 'Add job ' + @jobStr + ' to #Tmp_Job_Backfill_Details'

                        INSERT INTO #Tmp_Job_Backfill_Details
                                (DataPackageID, Job, BatchID, Priority, Created, Start, Finish, AnalysisToolID,
                                ParamFileName, SettingsFileName, OrganismDBName, OrganismID, DatasetID, Comment, Owner,
                                StateID, AssignedProcessorName, ResultsFolderName, ProteinCollectionList, ProteinOptionsList,
                                RequestID, PropagationMode, ProcessingTimeMinutes, Purged)
                        SELECT @dataPackageID,
                               @job,
                               0,                       -- BatchID
                               @priority,               -- Priority
                               @imported,               -- Created
                               @start,                  -- Start
                               @finish,                 -- Finish
                               @analysisToolID,         -- AnalysisToolID
                               @parameterFileName,      -- ParamFileName
                               'na',                    -- SettingsFileName
                               @legacyFastaFileName,    -- OrganismDBName
                               @organismID,             -- OrganismID
                               @datasetID,              -- DatasetID
                               Coalesce(@comment, ''),    -- Comment
                               @owner,                  -- Owner
                               @state,                  -- StateID
                               'Job_Broker',            -- AssignedProcessorName
                               @results_Folder_Name,    -- ResultsFolderName
                               @proteinCollectionList,  -- ProteinCollectionList
                               'na',                    -- ProteinOptionsList
                               1,                       -- RequestID
                               0,                       -- PropagationMode
                               @processingTimeMinutes,  -- ProcessingTimeMinutes
                               0                        -- Purged
                        --
                        Select @myRowCount = @@rowCount, @myError = @@error

                        If @myRowCount = 0
                        Begin
                            Set @message = 'Error adding new row to #Tmp_Job_Backfill_Details for job ' + @jobStr

                            If @infoOnly = 0
                                Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                            Else
                                Print @message

                        End

                        If @myRowCount > 0 And @infoOnly = 0
                        Begin
                            ------------------------------------------------
                            -- Append the job to T_Analysis_Job
                            ------------------------------------------------

                            Set @currentLocation = 'Add job ' + @jobStr + ' to T_Analysis_Job using #Tmp_Job_Backfill_Details'

                            INSERT INTO T_Analysis_Job
                                   (AJ_jobID, AJ_batchID, AJ_priority, AJ_created, AJ_start, AJ_finish, AJ_analysisToolID,
                                    AJ_parmFileName, AJ_settingsFileName, AJ_organismDBName, AJ_organismID, AJ_datasetID, AJ_comment, AJ_owner,
                                    AJ_StateID, AJ_assignedProcessorName, AJ_resultsFolderName, AJ_proteinCollectionList, AJ_proteinOptionsList,
                                    AJ_requestID, AJ_propagationMode, AJ_ProcessingTimeMinutes, AJ_Purged)
                            Select Job, BatchID, Priority, Created, Start, Finish, AnalysisToolID,
                                ParamFileName, SettingsFileName, OrganismDBName, OrganismID, DatasetID, Comment, Owner,
                                StateID, AssignedProcessorName, ResultsFolderName, ProteinCollectionList, ProteinOptionsList,
                                RequestID, PropagationMode, ProcessingTimeMinutes, Purged
                            FROM #Tmp_Job_Backfill_Details
                            WHERE Job = @job
                            --
                            Select @myRowCount = @@rowCount, @myError = @@error

                            If @myRowCount = 0
                            Begin
                                Set @message = 'Error adding DMS Pipeline job ' + @jobStr + ' to T_Analysis_Job'
                                Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                            End

                        End

                    End -- </d4>

                End -- </c>

            END TRY
            BEGIN CATCH
                -- Error caught; log the error then continue with the next job to backfill
                    Set @callingProcName = Coalesce(ERROR_PROCEDURE(), 'BackfillPipelineJobs')
                    exec LocalErrorHandler  @callingProcName, @currentLocation, @logError = 1,
                                            @errorNum = @myError output, @message = @message output
            END CATCH

        End -- </b>

NextJob:

        Set @jobsProcessed = @jobsProcessed + 1

        If @jobsToProcess > 0 And @jobsProcessed >= @jobsToProcess
            Set @continue = 0

    End -- </a>


    If @infoOnly > 0
    Begin
        ------------------------------------------------
        -- Preview the new jobs
        ------------------------------------------------

        SELECT *
        FROM #Tmp_Job_Backfill_Details
        ORDER BY Job
    End
    Else
    Begin -- <f>

        BEGIN TRY

            ------------------------------------------------
            -- Use a Merge query to update backfilled jobs where Start, Finish, State, or ProcessingTimeMinutes has changed
            -- Do not change a job from State 14 to a State > 4
            ------------------------------------------------

            Set @currentLocation = 'Synchronize T_Analysis_Job with back-filled DMS_Pipeline jobs'

            MERGE T_Analysis_Job AS target
            USING
                (    SELECT PJ.Job,
                        PJ.Priority,
                        PJ.State,
                        PJ.Start,
                        PJ.Finish,
                        PJ.Processing_Time_Minutes AS ProcessingTimeMinutes
                    FROM S_V_Pipeline_Jobs_Backfill PJ
                ) AS Source ( Job, Priority, State, Start, Finish, ProcessingTimeMinutes )
            ON (target.AJ_JobID = source.Job)
            WHEN Matched AND
                        (   Target.AJ_StateID <> 14 AND target.AJ_StateID <> source.State OR
                            Target.AJ_priority <> source.Priority OR
                            Coalesce(target.AJ_start ,'1/1/1990') <> Coalesce(source.Start,'1/1/1990') OR
                            Coalesce(target.AJ_finish ,'1/1/1990') <> Coalesce(source.Finish,'1/1/1990') OR
                            Coalesce(target.AJ_ProcessingTimeMinutes, 0) <> Coalesce(source.ProcessingTimeMinutes, 0)
                        )
            THEN UPDATE
                Set AJ_StateID = CASE WHEN Target.AJ_StateID = 14 Then 14 Else source.State End,
                    AJ_priority = source.Priority,
                    AJ_start = source.Start,
                    AJ_finish = source.Finish,
                    AJ_ProcessingTimeMinutes = source.ProcessingTimeMinutes
            ;

            Select @myRowCount = @@rowCount, @myError = @@error

            If @myError <> 0
            Begin
                Set @message = 'Error synchronizing T_Analysis_Job with S_V_Pipeline_Jobs_Backfill, error code ' + Convert(varchar(12), @myError)

                Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'

            End

        END TRY
        BEGIN CATCH
            -- Error caught; log the error then continue with the next job to backfill
                Set @callingProcName = Coalesce(ERROR_PROCEDURE(), 'BackfillPipelineJobs')
                exec LocalErrorHandler  @callingProcName, @currentLocation, @logError = 1,
                                        @errorNum = @myError output, @message = @message output
        END CATCH

    End -- </f>

Done:

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[BackfillPipelineJobs] TO [DDL_Viewer] AS [dbo]
GO
