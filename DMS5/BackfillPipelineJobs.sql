/****** Object:  StoredProcedure [dbo].[BackfillPipelineJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[BackfillPipelineJobs]
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
**    
*****************************************************/
(
    @infoOnly tinyint = 0,
    @JobsToProcess int = 0,                    -- Set to a positive number to process a finite number of jobs
    @message varchar(255) = '' OUTPUT
)
AS

    Set XACT_ABORT, nocount on

    declare @myRowCount int = 0 
    declare @myError int = 0
    
    Declare @Job int
    Declare @Priority int
    Declare @Script varchar(64)
    Declare @State int
    Declare @Dataset varchar(128)
    Declare @Results_Folder_Name varchar(128)
    Declare @Imported datetime
    Declare @Start datetime
    Declare @Finish datetime
    Declare @TransferFolderPath varchar(512)
    Declare @Comment varchar(512)
    Declare @Owner varchar(64)
    Declare @ProcessingTimeMinutes real
    
    Declare @Continue tinyint
    Declare @JobsProcessed int = 0
    Declare @PeptideAtlasStagingTask tinyint = 0
    
    Declare @AnalysisToolID int
    Declare @OrganismID int
    
    Declare @DatasetID int
    Declare @DatasetComment varchar(128)
    Declare @jobStr varchar(12)
    
    Declare @DataPackageID int
    Declare @DataPackageName varchar(128)
    Declare @DataPackageFolder varchar(256)
    Declare @StoragePathRelative varchar(256)
    
    Declare @mode varchar(12)
    Declare @msg varchar(256)
    
    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'


    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @JobsToProcess = IsNull(@JobsToProcess, 0)
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
        ParmFileName varchar(255) NOT NULL,
        SettingsFileName varchar(255) NULL,
        OrganismDBName varchar(64) NOT NULL,
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
               PJ.ProcessingTimeMinutes,
               PJ.DataPkgID
        FROM S_V_Pipeline_Jobs_Backfill PJ
             LEFT OUTER JOIN T_Analysis_Job J
               ON PJ.Job = J.AJ_jobID
        WHERE J.AJ_JobID IS NULL
        ORDER BY PJ.Job
        --
        Select @myRowCount = @@RowCount, @myError = @@Error
    End
    
    ---------------------------------------------------
    -- Process each job present in S_V_Pipeline_Jobs_Backfill that is not present in T_Analysis_Job
    ---------------------------------------------------
    
    Set @Job = 0
    Set @Continue = 1
    While @Continue <> 0
    Begin -- <a>

        SELECT TOP 1 @Job = PJ.Job,
                     @Priority = PJ.Priority,
                     @Script = PJ.Script,
                     @State = PJ.State,
                     @Dataset = PJ.Dataset,
                     @Results_Folder_Name = PJ.Results_Folder_Name,
                     @Imported = PJ.Imported,
                     @Start = PJ.Start,
                     @Finish = PJ.Finish,
                     @TransferFolderPath = PJ.Transfer_Folder_Path,
                     @Comment = PJ.[Comment],
                     @Owner = PJ.Owner,
                     @ProcessingTimeMinutes = PJ.ProcessingTimeMinutes,
                     @DataPackageID = PJ.DataPkgID
        FROM S_V_Pipeline_Jobs_Backfill PJ
             LEFT OUTER JOIN T_Analysis_Job J
               ON PJ.Job = J.AJ_jobID
        WHERE PJ.Job > @Job AND
              J.AJ_JobID IS NULL
        ORDER BY PJ.Job
        --
        Select @myRowCount = @@RowCount, @myError = @@Error
        
        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin -- <b>
            
            Set @jobStr = Convert(varchar(12), @job)
            
            BEGIN TRY 
            
                Set @CurrentLocation = 'Validate settings required to backfill job ' + @jobStr
                
                ---------------------------------------------------
                -- Lookup AnalysisToolID for @Script
                ---------------------------------------------------
                --
                Set @AnalysisToolID = -1
                
                SELECT @AnalysisToolID = AJT_toolID
                FROM T_Analysis_Tool
                WHERE (AJT_toolName = @Script)
                
                If @AnalysisToolID < 0
                Begin
                    Set @message = 'Script not found in T_Analysis_Tool: ' + @Script + '; unable to backfill DMS Pipeline job ' + @jobStr
                    
                    If @infoOnly > 0
                        print @message
                    Else
                        Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                    
                    Goto NextJob
                End
                
                If @Script = 'PeptideAtlas'
                    Set @PeptideAtlasStagingTask = 1
                Else
                    Set @PeptideAtlasStagingTask = 0
                
                ---------------------------------------------------
                -- Lookup OrganismID for organism 'None'
                ---------------------------------------------------
                --
                Set @OrganismID = -1
                
                SELECT @OrganismID = Organism_ID
                FROM T_Organisms
                WHERE (OG_name = 'None')
            
                If @OrganismID < 0
                Begin
                    Set @message = 'Organism "None" not found in T_Organisms -- this is unexpected; will set @OrganismID to 1'
                    
                    If @infoOnly > 0
                        print @message
                    Else
                        Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'                    
                        
                    Set @OrganismID = 1
                End
                
                ---------------------------------------------------
                -- Validate @Owner; update if not valid
                ---------------------------------------------------
                --
                If Not Exists (SELECT * FROM T_Users WHERE U_PRN = IsNull(@Owner, ''))
                    Set @Owner = 'H09090911'
                
                ---------------------------------------------------
                -- Validate @State; update if not valid
                ---------------------------------------------------
                --
                If Not Exists (SELECT * FROM T_Analysis_State_Name WHERE AJS_stateID = @State)
                Begin
                    Set @message = 'State ' + Convert(varchar(12), @State) + 'not found in T_Analysis_State_Name -- this is unexpected; will set @State to 4'
                    
                    If @infoOnly > 0
                        print @message
                    Else
                        Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'                    
                        
                    Set @State = 4
                End
                
                ------------------------------------------------
                -- Check whether dataset @Dataset exists if @dataset is <> 'Aggregation'
                ------------------------------------------------
                --
                Set @DatasetID = -1
                Set @DatasetComment = ''
                
                If IsNull(@Dataset, 'Aggregation') <> 'Aggregation'
                Begin
                    
                    SELECT @DatasetID = Dataset_ID
                    FROM T_Dataset
                    WHERE Dataset_Num = @Dataset
                    --
                    Select @myRowCount = @@RowCount, @myError = @@Error
                    
                END
                
                If @DatasetID < 0
                Begin -- <c>
                    ------------------------------------------------
                    -- Dataset does not exist; auto-define the dataset to associate with this job
                    -- First lookup the data package ID associated with this job
                    ------------------------------------------------
                    
                    Set @CurrentLocation = 'Auto-define the dataset to associate with job ' + @jobStr
                    
                    If @DataPackageID <= 0
                    Begin -- <d1>
                        ------------------------------------------------
                        -- Job doesn't have a data package ID
                        -- Simply set @Dataset to DP_Aggregation
                        ------------------------------------------------
                        Set @Dataset = 'DP_Aggregation'
                        
                    End -- </d1>
                    Else
                    Begin -- <d2>
                    
                        ------------------------------------------------
                        -- Lookup the Data Package name for @DataPackageID
                        ------------------------------------------------
                        
                        Set @DataPackageName = ''
                        Set @DataPackageFolder = ''
                        Set @StoragePathRelative = ''
                        
                        SELECT @DataPackageName = [Name],
                               @DataPackageFolder = Package_File_Folder,
                               @StoragePathRelative = Storage_Path_Relative
                        FROM S_V_Data_Package_Export
                        WHERE ID = @DataPackageID
                        --
                        Select @myRowCount = @@RowCount, @myError = @@Error
                    
                        If @myRowCount = 0 Or IsNull(@DataPackageFolder, '') = ''
                        Begin
                            -- Data Package not found (or Package_File_Folder is not defined)
                            Set @Dataset = 'DataPackage_' + Convert(varchar(12), @DataPackageID)
                        End
                        Else
                        Begin
                            -- Data Package found
                            Set @Dataset = 'DataPackage_' + @DataPackageFolder
                                                        
                            If @PeptideAtlasStagingTask <> 0
                            Begin
                                Set @Dataset = @Dataset + '_Staging'
                            End
                            
                        End
                        
                        Set @DatasetComment = 'http://dms2.pnl.gov/data_package/show/' + Convert(varchar(12), @DataPackageID)
                        
                    End -- </d2>
                    
                    If Len(@Dataset) > 80
                    Begin
                        -- Truncate the dataset name to avoid triggering an error in AddUpdateDataset
                        Set @Dataset = Substring(@Dataset, 1, 80)
                    End
                    
                    -- Make sure there are no spaces, periods, brackets, braces, or parentheses in @Dataset
                    Set @Dataset = Replace(@Dataset, ' ', '_')
                    Set @Dataset = Replace(@Dataset, '.', '_')
                    Set @Dataset = Replace(@Dataset, '[', '_')
                    Set @Dataset = Replace(@Dataset, ']', '_')
                    Set @Dataset = Replace(@Dataset, '{', '_')
                    Set @Dataset = Replace(@Dataset, '}', '_')
                    Set @Dataset = Replace(@Dataset, '(', '_')
                    Set @Dataset = Replace(@Dataset, ')', '_')
                    
                    ------------------------------------------------
                    -- Now that we have constructed the name of the dataset to auto-create, see if it already exists
                    ------------------------------------------------
                    
                    SELECT @DatasetID = Dataset_ID
                    FROM T_Dataset
                    WHERE Dataset_Num = @Dataset
                    --
                    Select @myRowCount = @@RowCount, @myError = @@Error
                    
                    If @myRowCount = 0
                        Set @DatasetID = -1

                
                    If @DatasetID < 0
                    Begin -- <d3>
                        
                        ------------------------------------------------
                        -- Dataset does not exist; create it
                        ------------------------------------------------
                        
                        Set @CurrentLocation = 'Call AddUpdateDataset to create dataset ' + @Dataset
                         
                        If @infoOnly > 0
                        Begin
                            Set @mode = 'check_add'
                            Print 'Check_add dataset ' + @Dataset
                        End
                        Else
                            Set @mode = 'add'
                            
                        Exec @myError = AddUpdateDataset
                                            @Dataset,               -- Dataset
                                            'DMS_Pipeline_Data',    -- Experiment
                                            'MSDADMIN',             -- Operator PRN
                                            'DMS_Pipeline_Data',    -- Instrument
                                            'DataFiles',            -- Dataset Type
                                            'unknown',              -- LC Column
                                            'na',                   -- Well plate
                                            'na',                   -- Well number
                                            'none',                 -- Secondary Sep
                                            'none',                 -- Internal Standard
                                            @DatasetComment,        -- Comment
                                            'Released',             -- Rating
                                            'No_Cart',              -- LC Cart
                                            '',                     -- EUS Proposal
                                            'CAP_DEV',              -- EUS Usage
                                            '',                     -- EUS Users
                                            @requestID = 0,
                                            @mode = @mode,
                                            @message = @msg output,
                                            @AggregationJobDataset = 1
                                                                                            
                        If @myError <> 0
                        Begin                        
                            ------------------------------------------------
                            -- Error creating dataset
                            ------------------------------------------------
                            
                            Set @message = 'Error creating dataset ' + @Dataset + ' for DMS Pipeline job ' + @jobStr
                            If IsNull(@msg, '') <> ''
                                Set @message = @message + ': ' + @msg
                            
                            If @infoOnly > 0
                                Print @message
                            Else                            
                                Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                                
                            Set @DatasetID = -1
                        End
                        Else
                        Begin -- <e>
                            If @infoOnly > 0
                            Begin
                                Set @DatasetID = 1
                            End
                            Else
                            Begin
                                ------------------------------------------------
                                -- Determine the DatasetID for the newly-created dataset
                                ------------------------------------------------
                                
                                Set @CurrentLocation = 'Determine DatasetID for newly created dataset ' + @Dataset
                                        
                                SELECT @DatasetID = Dataset_ID
                                FROM T_Dataset
                                WHERE Dataset_Num = @Dataset
                                --
                                Select @myRowCount = @@RowCount, @myError = @@Error
                                
                                If @myRowCount = 0
                                Begin
                                    Set @message = 'Error creating dataset ' + @Dataset + ' for DMS Pipeline job ' + @jobStr + '; call to AddUpdateDataset succeeded but dataset not found in T_Dataset'
                                    Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                                    Set @DatasetID = -1                        
                                End
                                
                                If IsNull(@StoragePathRelative, '') <> ''
                                Begin
                                    If @PeptideAtlasStagingTask <> 0
                                    Begin
                                        -- The data files will be stored at a path of the form:
                                        --   \\protoapps\PeptideAtlas_Staging\829_Organelle_Targeting_ABPP
                                        -- Need to determine the path ID
                                        
                                        Declare @PeptideAtlasStagingPathID int = 0
                                        
                                        SELECT @PeptideAtlasStagingPathID = SP_path_ID
                                        FROM T_Storage_Path
                                        WHERE (SP_path IN ('PeptideAtlas_Staging', 'PeptideAtlas_Staging\'))

                                        If IsNull(@PeptideAtlasStagingPathID, 0) > 0
                                        Begin
                                            UPDATE T_Dataset
                                            SET DS_Storage_Path_ID = @PeptideAtlasStagingPathID
                                            WHERE Dataset_ID = @DatasetID
                                            
                                            Set @StoragePathRelative = @DataPackageFolder
                                        End
                                    End
                                    
                                    -- Update the Dataset Folder for the newly-created dataset
                                    UPDATE T_Dataset
                                    SET DS_folder_name = @StoragePathRelative
                                    WHERE Dataset_ID = @DatasetID
                                End

                            End
                                                
                        End -- </e>
                        
                    End -- </d3>

                    If @DatasetID > 0
                    Begin -- <d4>
                    
                        ------------------------------------------------
                        -- Dataset is now defined for job to backfill
                        -- Add a new row to #Tmp_Job_Backfill_Details
                        ------------------------------------------------

                        Set @CurrentLocation = 'Add job ' + @jobStr + ' to #Tmp_Job_Backfill_Details'

                        INSERT INTO #Tmp_Job_Backfill_Details
                                (DataPackageID, Job, BatchID, Priority, Created, Start, Finish, AnalysisToolID, 
                                ParmFileName, SettingsFileName, OrganismDBName, OrganismID, DatasetID, Comment, Owner, 
                                StateID, AssignedProcessorName, ResultsFolderName, ProteinCollectionList, ProteinOptionsList, 
                                RequestID, PropagationMode, ProcessingTimeMinutes, Purged)
                        SELECT @DataPackageID,
                               @Job,
                               0,                       -- batchID
                               @Priority,               -- priority
                               @Imported,               -- created
                               @Start,                  -- start
                               @Finish,                 -- finish
                               @AnalysisToolID,         -- analysisToolID
                               'na',                    -- parmFileName
                               'na',                    -- settingsFileName
                               'na',                    -- organismDBName
                               @OrganismID,             -- organismID
                               @DatasetID,              -- datasetID
                               IsNull(@Comment, ''),    -- comment
                               @Owner,                  -- owner
                               @State,                  -- StateID
                               'Job_Broker',            -- assignedProcessorName
                               @Results_Folder_Name,    -- resultsFolderName
                               'na',                    -- proteinCollectionList
                               'na',                    -- proteinOptionsList
                               1,                       -- requestID
                               0,                       -- propagationMode                                
                               @ProcessingTimeMinutes,  -- ProcessingTimeMinutes
                               0                        -- Purged                               
                        --
                        Select @myRowCount = @@RowCount, @myError = @@Error
                        
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

                            Set @CurrentLocation = 'Add job ' + @jobStr + ' to T_Analysis_Job using #Tmp_Job_Backfill_Details'
                                                    
                            INSERT INTO T_Analysis_Job
                                   (AJ_jobID, AJ_batchID, AJ_priority, AJ_created, AJ_start, AJ_finish, AJ_analysisToolID, 
                                    AJ_parmFileName, AJ_settingsFileName, AJ_organismDBName, AJ_organismID, AJ_datasetID, AJ_comment, AJ_owner, 
                                    AJ_StateID, AJ_assignedProcessorName, AJ_resultsFolderName, AJ_proteinCollectionList, AJ_proteinOptionsList, 
                                    AJ_requestID, AJ_propagationMode, AJ_ProcessingTimeMinutes, AJ_Purged)
                            Select Job, BatchID, Priority, Created, Start, Finish, AnalysisToolID, 
                                ParmFileName, SettingsFileName, OrganismDBName, OrganismID, DatasetID, Comment, Owner, 
                                StateID, AssignedProcessorName, ResultsFolderName, ProteinCollectionList, ProteinOptionsList, 
                                RequestID, PropagationMode, ProcessingTimeMinutes, Purged
                            FROM #Tmp_Job_Backfill_Details
                            WHERE Job = @Job
                            --
                            Select @myRowCount = @@RowCount, @myError = @@Error
                            
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
                    Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'BackfillPipelineJobs')
                    exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
                                            @ErrorNum = @myError output, @message = @message output
            END CATCH
                
        End -- </b>

NextJob:

        Set @JobsProcessed = @JobsProcessed + 1
        
        If @JobsToProcess > 0 And @JobsProcessed >= @JobsToProcess
            Set @Continue = 0
            
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
            
            Set @CurrentLocation = 'Synchronize T_Analysis_Job with back-filled DMS_Pipeline jobs'
            
            MERGE T_Analysis_Job AS target
            USING 
                (    SELECT PJ.Job,
                        PJ.Priority,
                        PJ.State,
                        PJ.Start,
                        PJ.Finish,
                        PJ.ProcessingTimeMinutes
                    FROM S_V_Pipeline_Jobs_Backfill PJ
                ) AS Source ( Job, Priority, State, Start, Finish, ProcessingTimeMinutes )
            ON (target.AJ_JobID = source.Job)
            WHEN Matched AND 
                        (   Target.AJ_StateID <> 14 AND target.AJ_StateID <> source.State OR
                            Target.AJ_priority <> source.Priority OR
                            IsNull(target.AJ_start ,'1/1/1990') <> IsNull(source.Start,'1/1/1990') OR
                            IsNull(target.AJ_finish ,'1/1/1990') <> IsNull(source.Finish,'1/1/1990') OR
                            IsNull(target.AJ_ProcessingTimeMinutes, 0) <> IsNull(source.ProcessingTimeMinutes, 0)
                        )
            THEN UPDATE 
                Set AJ_StateID = CASE WHEN Target.AJ_StateID = 14 Then 14 Else source.State End, 
                    AJ_priority = source.Priority,
                    AJ_start = source.Start,
                    AJ_finish = source.Finish,
                    AJ_ProcessingTimeMinutes = source.ProcessingTimeMinutes
            ;

            Select @myRowCount = @@RowCount, @myError = @@Error

            If @myError <> 0
            Begin
                Set @message = 'Error synchronizing T_Analysis_Job with S_V_Pipeline_Jobs_Backfill, error code ' + Convert(varchar(12), @myError)

                Exec PostLogEntry 'Error', @message, 'BackfillPipelineJobs'
                
            End

        END TRY
        BEGIN CATCH 
            -- Error caught; log the error then continue with the next job to backfill
                Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'BackfillPipelineJobs')
                exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
                                        @ErrorNum = @myError output, @message = @message output
        END CATCH
        
    End -- </f>
    
Done:

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[BackfillPipelineJobs] TO [DDL_Viewer] AS [dbo]
GO
