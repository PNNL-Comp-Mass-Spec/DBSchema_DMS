/****** Object:  StoredProcedure [dbo].[add_update_analysis_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_analysis_job]
/****************************************************
**
**  Desc:
**      Adds new analysis job to job table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/10/2002
**          01/30/2004 fixed @@identity problem with insert
**          05/06/2004 grk - allowed analysis processor preset
**          11/05/2004 grk - added parameter for assigned processor
**                           removed batchID parameter
**          02/10/2005 grk - fixed update to include assigned processor
**          03/28/2006 grk - added protein collection fields
**          04/04/2006 grk - increased size of param file name
**          04/07/2006 grk - revised validation logic to use validate_analysis_job_parameters
**          04/11/2006 grk - added state field and reset mode
**          04/21/2006 grk - reset now allowed even if job not in "new" state
**          06/01/2006 grk - added code to handle '(default)' organism
**          11/30/2006 mem - Added column Dataset_Type to #TD (Ticket #335)
**          12/20/2006 mem - Added column DS_rating to #TD (Ticket #339)
**          01/13/2007 grk - switched to organism ID instead of organism name (Ticket #360)
**          02/07/2007 grk - eliminated "Spectra Required" states (Ticket #249)
**          02/15/2007 grk - added associated processor group (Ticket #383)
**          02/15/2007 grk - Added propagation mode (Ticket #366)
**          02/21/2007 grk - removed @assignedProcessor (Ticket #383)
**          10/11/2007 grk - Expand protein collection list size to 4000 characters (http://prismtrac.pnl.gov/trac/ticket/545)
**          01/17/2008 grk - Modified error codes to help debugging DMS2.  Also had to add explicit NULL column attribute to #TD
**          02/22/2008 mem - Updated to allow updating jobs in state "holding"
**                         - Updated to convert @comment and @associatedProcessorGroup to '' if null (Ticket #648)
**          02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call alter_event_log_entry_user (Ticket #644, http://prismtrac.pnl.gov/trac/ticket/644)
**          04/22/2008 mem - Updated to call alter_entered_by_user when updating T_Analysis_Job_Processor_Group_Associations
**          09/12/2008 mem - Now passing @paramFileName and @settingsFileName ByRef to validate_analysis_job_parameters (Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688)
**          02/27/2009 mem - Expanded @comment to varchar(512)
**          04/15/2009 grk - handles wildcard DTA folder name in comment field (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          08/05/2009 grk - assign job number from separate table (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          05/05/2010 mem - Now passing @ownerUsername to validate_analysis_job_parameters as input/output
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          08/18/2010 mem - Now allowing job update if state is Failed, in addition to New or Holding
**          08/19/2010 grk - try-catch for error handling
**          08/26/2010 mem - Added parameter @PreventDuplicateJobs
**          03/29/2011 grk - Added @specialProcessing argument (http://redmine.pnl.gov/issues/304)
**          04/26/2011 mem - Added parameter @PreventDuplicatesIgnoresNoExport
**          05/24/2011 mem - Now populating column AJ_DatasetUnreviewed when adding new jobs
**          05/03/2012 mem - Added parameter @SpecialProcessingWaitUntilReady
**          06/12/2012 mem - Removed unused code related to Archive State in #TD
**          09/18/2012 mem - Now clearing @organismDBName if @mode='reset' and we're searching a protein collection
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          01/04/2013 mem - Now ignoring @organismName, @protCollNameList, @protCollOptionsList, and @organismDBName for analysis tools that do not use protein collections (AJT_orgDbReqd = 0)
**          04/02/2013 mem - Now updating @msg if it is blank yet @result is non-zero
**          03/13/2014 mem - Now passing @Job to validate_analysis_job_parameters
**          04/08/2015 mem - Now passing @autoUpdateSettingsFileToCentroided and @Warning to validate_analysis_job_parameters
**          05/28/2015 mem - No longer creating processor group entries (thus @associatedProcessorGroup is ignored)
**          06/24/2015 mem - Added parameter @infoOnly
**          07/21/2015 mem - Now allowing job comment and Export Mode to be changed
**          01/20/2016 mem - Update comments
**          02/15/2016 mem - Re-enabled handling of @associatedProcessorGroup
**          02/23/2016 mem - Add Set XACT_ABORT on
**          07/20/2016 mem - Expand error messages
**          11/18/2016 mem - Log try/catch errors using post_log_entry
**          12/05/2016 mem - Exclude logging some try/catch errors
**          12/16/2016 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/09/2017 mem - Add support for state 13 (inactive)
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/09/2017 mem - Allow job state to be changed from Complete (state 4) to No Export (state 14) if @propagationMode is 1 (aka 'No Export')
**          12/06/2017 mem - Set @allowNewDatasets to 0 when calling validate_analysis_job_parameters
**          06/12/2018 mem - Send @maxLength to append_to_text
**          09/05/2018 mem - When @mode is 'add', if @state is 'hold' or 'holding', create the job, but put it on hold (state 8)
**          06/30/2022 mem - Rename parameter file argument
**          07/29/2022 mem - Assure that the parameter file and settings file names are not null
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/22/2023 mem - Rename column in temp table
**          07/27/2023 mem - Update message sent to get_new_job_id()
**          09/09/2023 mem - Prevent updating a job's state to "Complete" using this procedure
**
*****************************************************/
(
    @datasetName varchar(128),
    @priority int = 2,
    @toolName varchar(64),
    @paramFileName varchar(255),
    @settingsFileName varchar(255),
    @organismName varchar(128),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @organismDBName varchar(128),
    @ownerUsername varchar(64),
    @comment varchar(512) = null,
    @specialProcessing varchar(512) = null,
    @associatedProcessorGroup varchar(64) = '',     -- Processor group
    @propagationMode varchar(24),                   -- Propagation mode, aka export mode
    @stateName varchar(32),                         -- Job state when updating or resetting the job.  When @mode is 'add', if this is 'hold' or 'holding', the job will be created and placed in state holding
    @job varchar(32) = '0' output,               -- New job number if adding a job; existing job number if updating or resetting a job
    @mode varchar(12) = 'add',  -- or 'update' or 'reset'; use 'previewadd' or 'previewupdate' to validate the parameters but not actually make the change (used by the Spreadsheet loader page)
    @message varchar(512) output,
    @callingUser varchar(128) = '',
    @preventDuplicateJobs tinyint = 0,              -- Only used if @Mode is 'add'; ignores jobs with state 5 (failed), 13 (inactive) or 14 (no export)
    @preventDuplicatesIgnoresNoExport tinyint = 1,
    @specialProcessingWaitUntilReady tinyint = 0,   -- When 1, then sets the job state to 19="Special Proc. Waiting" when the @specialProcessing parameter is not empty
    @infoOnly tinyint = 0                           -- When 1, preview the change even when @mode is 'add' or 'update'
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @AlterEnteredByRequired tinyint = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @paramFileName = LTrim(RTrim(Coalesce(@paramFileName, '')))
    Set @settingsFileName = LTrim(RTrim(Coalesce(@settingsFileName, '')))

    Set @comment = LTrim(RTrim(Coalesce(@comment, '')))
    Set @associatedProcessorGroup = LTrim(RTrim(Coalesce(@associatedProcessorGroup, '')))
    Set @callingUser = LTrim(RTrim(Coalesce(@callingUser, '')))
    Set @PreventDuplicateJobs = Coalesce(@PreventDuplicateJobs, 0)
    Set @PreventDuplicatesIgnoresNoExport = Coalesce(@PreventDuplicatesIgnoresNoExport, 1)
    Set @infoOnly = Coalesce(@infoOnly, 0)

    Set @message = ''

    Declare @msg varchar(256)

    Declare @batchID int = 0
    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_analysis_job', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates and resets)
    ---------------------------------------------------

    Declare @jobID int = 0
    Declare @currentStateID int = 0

    If @mode = 'update' or @mode = 'reset'
    Begin
        -- cannot update a non-existent entry
        --
        SELECT
            @jobID = AJ_jobID,
            @currentStateID = AJ_StateID
        FROM T_Analysis_Job
        WHERE AJ_jobID = Try_Cast(@job AS int)

        If @jobID = 0
        Begin
            Set @msg = 'Cannot update: Analysis Job "' + @job + '" is not in database'
            If @infoOnly <> 0
                print @msg

            RAISERROR (@msg, 11, 4)
        End

    End

    ---------------------------------------------------
    -- Resolve propagation mode
    ---------------------------------------------------
    Declare @propMode smallint
    Set @propMode = CASE @propagationMode
                        WHEN 'Export' THEN 0
                        WHEN 'No Export' THEN 1
                        ELSE 0
                    End

    If @mode = 'update'
    Begin
        Declare @currentStateName varchar(32)

        -- Changes are typically only allowed to jobs in 'new', 'failed', or 'holding' state
        -- However, we do allow the job comment or export mode to be updated

        If @currentStateID <> 4 And @stateName = 'Complete'
        Begin
            SELECT @currentStateName = ASN.AJS_name
            FROM T_Analysis_Job J
                 INNER JOIN T_Analysis_State_Name ASN
                   ON J.AJ_StateID = ASN.AJS_stateID
            WHERE J.AJ_jobID = @jobID

            Set @msg = 'State for Analysis Job ' + @job + ' cannot be changed from "' + @currentStateName + '" to "Complete"'
            If @infoOnly <> 0
                print @msg

            RAISERROR (@msg, 11, 5)
        End

        If Not @currentStateID IN (1,5,8,19)
        Begin
            -- Allow the job comment and Export Mode to be updated

            Declare @currentExportMode smallint
            Declare @currentComment varchar(512)

            SELECT @currentStateName = ASN.AJS_name,
                   @currentComment = Coalesce(J.AJ_comment, ''),
                   @currentExportMode = Coalesce(J.AJ_propagationMode, 0)
            FROM T_Analysis_Job J
                 INNER JOIN T_Analysis_State_Name ASN
                   ON J.AJ_StateID = ASN.AJS_stateID
            WHERE J.AJ_jobID = @jobID

            If @comment <> @currentComment Or
               @propMode <> @currentExportMode Or
               @currentStateName = 'Complete' And @stateName = 'No export'
            Begin
                If @infoOnly = 0
                Begin
                    UPDATE T_Analysis_Job
                    SET AJ_comment = @comment,
                        AJ_propagationMode = @propMode
                    WHERE AJ_jobID = @jobID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                End

                If @comment <> @currentComment And @propMode <> @currentExportMode
                    Set @message = 'Updated job comment and export mode'

                If @message = '' And @comment <> @currentComment
                    Set @message = 'Updated job comment'

                If @message = '' And @propMode <> @currentExportMode
                    Set @message = 'Updated export mode'

                If @stateName <> @currentStateName
                Begin
                    If @propMode = 1 And @currentStateName = 'Complete' And @stateName = 'No export'
                    Begin
                        If @infoOnly = 0
                        Begin
                            UPDATE T_Analysis_Job
                            SET AJ_StateID = 14
                            WHERE AJ_jobID = @jobID
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount
                        End

                        Set @message = dbo.append_to_text(@message, 'set job state to "No export"', 0, '; ', 512)
                    End
                    Else
                    Begin
                        Set @msg = 'job state cannot be changed from ' + @currentStateName + ' to ' + @stateName
                        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 512)

                        If @propagationMode = 'Export' And @stateName = 'No export'
                        Begin
                            -- Job propagation mode is Export (0) but user wants to set the state to No export
                            Set @message = dbo.append_to_text(@message, 'to make this change, set the Export Mode to "No Export"', 0, '; ', 512)
                        End
                    End
                End

                If @infoOnly <> 0
                    Set @message = 'Preview: ' + @message

                Goto Done
            End

            Set @msg = 'Cannot update: Analysis Job "' + @job + '" is not in "new", "holding", or "failed" state'
            If @infoOnly <> 0
                print @msg

            RAISERROR (@msg, 11, 5)
        End
    End

    If @mode = 'reset'
    Begin
        If @organismDBName Like 'ID[_]%' And Coalesce(@protCollNameList, '') Not In ('', 'na')
        Begin
            -- We are resetting a job that used a protein collection; clear @organismDBName
            Set @organismDBName = ''
        End
    End

    ---------------------------------------------------
    -- Resolve processor group ID
    ---------------------------------------------------
    --
    Declare @gid int = 0
    --
    If @associatedProcessorGroup <> ''
    Begin
        SELECT @gid = ID
        FROM T_Analysis_Job_Processor_Group
        WHERE (Group_Name = @associatedProcessorGroup)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Error trying to resolve processor group name'
            RAISERROR (@msg, 11, 8)
        End
        --
        If @gid = 0
        Begin
            Set @msg = 'Processor group name not found'
            RAISERROR (@msg, 11, 9)
        End
    End

    ---------------------------------------------------
    -- Create temporary table to hold the dataset details
    -- This table will only have one row
    ---------------------------------------------------

    CREATE TABLE #TD (
        Dataset_Name varchar(128),
        Dataset_ID int NULL,
        IN_class varchar(64) NULL,
        DS_state_ID int NULL,
        AS_state_ID int NULL,
        Dataset_Type varchar(64) NULL,
        DS_rating smallint NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Failed to create temporary table #TD'
        If @infoOnly <> 0
            print @msg

        RAISERROR (@msg, 11, 7)
    End

    ---------------------------------------------------
    -- Add dataset to table
    ---------------------------------------------------
    --
    INSERT INTO #TD (Dataset_Name)
    VALUES (@datasetName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error populating temporary table with dataset name'
        If @infoOnly <> 0
            print @msg

        RAISERROR (@msg, 11, 11)
    End

    ---------------------------------------------------
    -- handle '(default)' organism
    ---------------------------------------------------

    If @organismName = '(default)'
    Begin
        SELECT
            @organismName = T_Organisms.OG_name
        FROM
            T_Experiments INNER JOIN
            T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID INNER JOIN
            T_Organisms ON T_Experiments.Ex_organism_ID = T_Organisms.Organism_ID
        WHERE
            (T_Dataset.Dataset_Num = @datasetName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Error resolving default organism name'
            If @infoOnly <> 0
                print @msg

            RAISERROR (@msg, 11, 12)
        End
    End

    ---------------------------------------------------
    -- validate job parameters
    ---------------------------------------------------
    --
    Declare @userID int
    Declare @analysisToolID int
    Declare @organismID int
    --
    Declare @result int = 0

    Declare @Warning varchar(255) = ''
    Set @msg = ''
    --
    exec @result = validate_analysis_job_parameters
                            @toolName = @toolName,
                            @paramFileName = @paramFileName output,
                            @settingsFileName = @settingsFileName output,
                            @organismDBName = @organismDBName output,
                            @organismName = @organismName,
                            @protCollNameList = @protCollNameList output,
                            @protCollOptionsList = @protCollOptionsList output,
                            @ownerUsername = @ownerUsername output,
                            @mode = @mode,
                            @userID = @userID output,
                            @analysisToolID = @analysisToolID output,
                            @organismID = @organismID output,
                            @message = @msg output,
                            @AutoRemoveNotReleasedDatasets = 0,
                            @Job = @jobID,
                            @autoUpdateSettingsFileToCentroided = 1,
                            @allowNewDatasets = 0,
                            @Warning = @Warning output,
                            @showDebugMessages = @infoOnly
    --
    If @result <> 0
    Begin
        If Coalesce(@msg, '') = ''
            Set @msg = 'Error code ' + Convert(varchar(12), @result) + ' returned by validate_analysis_job_parameters'

        If @infoOnly <> 0
            print @msg

        RAISERROR (@msg, 11, 18)
    End

    If Coalesce(@Warning, '') <> ''
    Begin
        Set @comment = dbo.append_to_text(@comment, @Warning, 0, '; ', 512)

        If @mode Like 'preview%'
            Set @message = @warning

    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Lookup the Dataset ID
    ---------------------------------------------------
    --
    Declare @datasetID int
    --
    SELECT TOP 1 @datasetID = Dataset_ID FROM #TD

    ---------------------------------------------------
    -- Set up transaction variables
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'add_update_analysis_job'

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin

        If @PreventDuplicateJobs <> 0
        Begin
            ---------------------------------------------------
            -- See if an existing, matching job already exists
            -- If it does, do not add another job
            ---------------------------------------------------

            Declare @ExistingJobCount int = 0
            Declare @ExistingMatchingJob int = 0

            SELECT @ExistingJobCount = COUNT(*),
                   @ExistingMatchingJob = MAX(AJ_JobID)
            FROM
                T_Dataset DS INNER JOIN
                T_Analysis_Job AJ ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
                T_Analysis_Tool AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID INNER JOIN
                T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID  INNER JOIN
                T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID INNER JOIN
                #TD ON #TD.Dataset_Name = DS.Dataset_Num
            WHERE
                ( @PreventDuplicatesIgnoresNoExport > 0 AND NOT AJ.AJ_StateID IN (5, 13, 14) OR
                  @PreventDuplicatesIgnoresNoExport = 0 AND AJ.AJ_StateID <> 5
                ) AND
                AJT.AJT_toolName = @toolName AND
                AJ.AJ_parmFileName = @paramFileName AND
                AJ.AJ_settingsFileName = @settingsFileName AND
                (
                  ( @protCollNameList = 'na' AND
                    AJ.AJ_organismDBName = @organismDBName AND
                    Org.OG_name = Coalesce(@organismName, Org.OG_name)
                  ) OR
                  ( @protCollNameList <> 'na' AND
                    AJ.AJ_proteinCollectionList = Coalesce(@protCollNameList, AJ.AJ_proteinCollectionList) AND
                     AJ.AJ_proteinOptionsList = Coalesce(@protCollOptionsList, AJ.AJ_proteinOptionsList)
                  ) OR
                  ( AJT.AJT_orgDbReqd = 0 )
                )

            If @ExistingJobCount > 0
            Begin
                Set @message = 'Job not created since duplicate job exists: ' + Convert(varchar(12), @ExistingMatchingJob)

                If @infoOnly <> 0
                    print @message

                -- Do not change this error code since SP create_predefined_analysis_jobs
                -- checks for error code 52500
                return 52500
            End
        End


        ---------------------------------------------------
        -- Check whether the dataset is unreviewed
        ---------------------------------------------------
        Declare @DatasetUnreviewed tinyint = 0

        IF Exists (SELECT * FROM T_Dataset WHERE Dataset_ID = @datasetID AND DS_Rating = -10)
            Set @DatasetUnreviewed = 1


        ---------------------------------------------------
        -- Get ID for new job
        ---------------------------------------------------
        --
        exec @jobID = get_new_job_id 'Created in t_analysis_job', @infoOnly
        If @jobID = 0
        Begin
            Set @msg = 'Failed to get valid new job ID'
            If @infoOnly <> 0
                print @msg

            RAISERROR (@msg, 11, 15)
        End
        Set @job = cast(@jobID as varchar(32))

        Declare @newStateID int = 1

        If Coalesce(@SpecialProcessingWaitUntilReady, 0) > 0 And Coalesce(@specialProcessing, '') <> ''
            Set @newStateID = 19

        If @stateName Like 'hold%'
            Set @newStateID = 8

        If @infoOnly <> 0
        Begin
            SELECT 'Preview ' + @mode as Mode,
                   @jobID AS AJ_jobID,
                   @priority AS AJ_priority,
                   getdate() AS AJ_created,
                   @analysisToolID AS AJ_analysisToolID,
                   @paramFileName AS AJ_parmFileName,
                   @settingsFileName AS AJ_settingsFileName,
                   @organismDBName AS AJ_organismDBName,
                   @protCollNameList AS AJ_proteinCollectionList,
                   @protCollOptionsList AS AJ_proteinOptionsList,
                   @organismID AS AJ_organismID,
                   @datasetID AS AJ_datasetID,
                   REPLACE(@comment, '#DatasetNum#', CONVERT(varchar(12), @datasetID)) AS AJ_comment,
                   @specialProcessing AS AJ_specialProcessing,
                   @ownerUsername AS AJ_owner,
                   @batchID AS AJ_batchID,
                   @newStateID AS AJ_StateID,
                   @propMode AS AJ_propagationMode,
                   @DatasetUnreviewed AS AJ_DatasetUnreviewed

        End
        Else
        Begin
            ---------------------------------------------------
            -- start transaction
            --
            Begin transaction @transName

            ---------------------------------------------------
            --
            INSERT INTO T_Analysis_Job (
                AJ_jobID,
                AJ_priority,
                AJ_created,
                AJ_analysisToolID,
                AJ_parmFileName,
                AJ_settingsFileName,
                AJ_organismDBName,
                AJ_proteinCollectionList,
                AJ_proteinOptionsList,
                AJ_organismID,
                AJ_datasetID,
                AJ_comment,
                AJ_specialProcessing,
                AJ_owner,
                AJ_batchID,
                AJ_StateID,
                AJ_propagationMode,
                AJ_DatasetUnreviewed
            ) VALUES (
                @jobID,
                @priority,
                getdate(),
                @analysisToolID,
                @paramFileName,
                @settingsFileName,
                @organismDBName,
                @protCollNameList,
                @protCollOptionsList,
                @organismID,
                @datasetID,
                REPLACE(@comment, '#DatasetNum#', CONVERT(varchar(12), @datasetID)),
                @specialProcessing,
                @ownerUsername,
                @batchID,
                @newStateID,
                @propMode,
                @DatasetUnreviewed
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Insert new job operation failed'
                If @infoOnly <> 0
                    print @msg

                RAISERROR (@msg, 11, 13)
            End

            -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
            If Len(@callingUser) > 0
                Exec alter_event_log_entry_user 5, @jobID, @newStateID, @callingUser

            ---------------------------------------------------
            -- Associate job with processor group
            --
            If @gid <> 0
            Begin
                INSERT INTO T_Analysis_Job_Processor_Group_Associations
                    (Job_ID, Group_ID)
                VALUES
                    (@jobID, @gid)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    Set @msg = 'Insert new job association failed'
                    RAISERROR (@msg, 11, 14)
                End
            End

            commit transaction @transName
        End
    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update' or @mode = 'reset'
    Begin
        Set @myError = 0

        ---------------------------------------------------
        -- Resolve state ID according to mode and state name
        --
        Declare @updateStateID int = -1
        --
        If @mode = 'reset'
        Begin
            Set @updateStateID = 1
        End
        Else
        Begin
            --
            SELECT @updateStateID = AJS_stateID
            FROM T_Analysis_State_Name
            WHERE (AJS_name = @stateName)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Error looking up state name'
                If @infoOnly <> 0
                    print @msg

                RAISERROR (@msg, 11, 15)
            End

            If @updateStateID = -1
            Begin
                Set @msg = 'State name not recognized: ' + @stateName
                If @infoOnly <> 0
                    print @msg

                RAISERROR (@msg, 11, 15)
            End
        End

        ---------------------------------------------------
        -- Associate job with processor group
        ---------------------------------------------------
        --
        -- Is there an existing association between the job
        -- and a processor group?
        --
        Declare @pgaAssocID int = 0
        --
        SELECT @pgaAssocID = Group_ID
        FROM T_Analysis_Job_Processor_Group_Associations
        WHERE Job_ID = @jobID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Error looking up existing job association'
            RAISERROR (@msg, 11, 16)
        End

        If @infoOnly <> 0
        Begin
            SELECT 'Preview ' + @mode as Mode,
                   @jobID AS AJ_jobID,
                   @priority AS AJ_priority,
                   AJ_created,
                   @analysisToolID AS AJ_analysisToolID,
                   @paramFileName AS AJ_parmFileName,
                   @settingsFileName AS AJ_settingsFileName,
                   @organismDBName AS AJ_organismDBName,
                   @protCollNameList AS AJ_proteinCollectionList,
                   @protCollOptionsList AS AJ_proteinOptionsList,
                   @organismID AS AJ_organismID,
                   @datasetID AS AJ_datasetID,
                  @comment AJ_comment,
                   @specialProcessing AS AJ_specialProcessing,
                   @ownerUsername AS AJ_owner,
                   AJ_batchID,
                   @updateStateID AS AJ_StateID,
                   CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL End AS AJ_start,
                   CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL End AS AJ_finish,
                   @propMode AS AJ_propagationMode,
                   AJ_DatasetUnreviewed
            FROM T_Analysis_Job
            WHERE (AJ_jobID = @jobID)

        End
        Else
        Begin
            ---------------------------------------------------
            -- start transaction
            --
            Begin transaction @transName

            ---------------------------------------------------
            -- make changes to database
            --
            UPDATE T_Analysis_Job
            SET AJ_priority = @priority,
                AJ_analysisToolID = @analysisToolID,
                AJ_parmFileName = @paramFileName,
                AJ_settingsFileName = @settingsFileName,
                AJ_organismDBName = @organismDBName,
                AJ_proteinCollectionList = @protCollNameList,
                AJ_proteinOptionsList = @protCollOptionsList,
                AJ_organismID = @organismID,
                AJ_datasetID = @datasetID,
                AJ_comment = @comment,
                AJ_specialProcessing = @specialProcessing,
                AJ_owner = @ownerUsername,
                AJ_StateID = @updateStateID,
                AJ_start = CASE WHEN @mode <> 'reset' THEN AJ_start ELSE NULL End,
                AJ_finish = CASE WHEN @mode <> 'reset' THEN AJ_finish ELSE NULL End,
                AJ_propagationMode = @propMode
            WHERE AJ_jobID = @jobID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @msg = 'Update operation failed: "' + @job + '"'
                RAISERROR (@msg, 11, 17)
            End

            -- If @callingUser is defined, then call alter_event_log_entry_user to alter the Entered_By field in T_Event_Log
            If Len(@callingUser) > 0
                Exec alter_event_log_entry_user 5, @jobID, @updateStateID, @callingUser

            ---------------------------------------------------
            -- Deal with job association with group,
            ---------------------------------------------------
            --
            -- If no group is given, but existing association
            -- exists for job, delete it
            --
            If @gid = 0
            Begin
                DELETE FROM T_Analysis_Job_Processor_Group_Associations
                WHERE (Job_ID = @jobID)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
            End

            -- If group is given, and no association for job exists
            -- create one
            --
            If @gid <> 0 and @pgaAssocID = 0
            Begin
                INSERT INTO T_Analysis_Job_Processor_Group_Associations
                    (Job_ID, Group_ID)
                VALUES
                    (@jobID, @gid)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --

                Set @AlterEnteredByRequired = 1
            End

            -- If group is given, and an association for job does exist update it

            If @gid <> 0 and @pgaAssocID <> 0 and @pgaAssocID <> @gid
            Begin
                UPDATE T_Analysis_Job_Processor_Group_Associations
                SET Group_ID = @gid,
                    Entered = GetDate(),
                    Entered_By = suser_sname()
                WHERE Job_ID = @jobID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --

                Set @AlterEnteredByRequired = 1
            End

            -- Report error, if one occurred
            --
            If @myError <> 0
            Begin
                Set @msg = 'Error deleting existing association for job'
                RAISERROR (@msg, 11, 21)
            End

            commit transaction @transName

            If Len(@callingUser) > 0 AND @AlterEnteredByRequired <> 0
            Begin
                -- Call alter_entered_by_user
                -- to alter the Entered_By field in T_Analysis_Job_Processor_Group_Associations

                Exec alter_entered_by_user 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @jobID, @CallingUser
            End
        End

    End -- update mode

    End Try
    Begin Catch
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Job ' + @job
            exec post_log_entry 'Error', @logMessage, 'add_update_analysis_job'
        End

    End Catch

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_analysis_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_analysis_job] TO [Limited_Table_Write] AS [dbo]
GO
