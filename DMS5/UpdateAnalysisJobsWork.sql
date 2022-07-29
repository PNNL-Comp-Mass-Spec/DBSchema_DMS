/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobsWork] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateAnalysisJobsWork]
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in temporary table #TAJ
**
**      The calling table must create table #Tmp_JobList
**
**      CREATE TABLE #TAJ (job int)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   04/06/2006
**          04/10/2006 grk - widened size of list argument to 6000 characters
**          04/12/2006 grk - eliminated forcing null for blank assigned processor
**          06/20/2006 jds - added support to find/replace text in the comment field
**          08/02/2006 grk - clear the AJ_ResultsFolderName, AJ_extractionProcessor,
**                         AJ_extractionStart, and AJ_extractionFinish fields when resetting a job
**          11/15/2006 grk - add logic for propagation mode (ticket #328)
**          03/02/2007 grk - add @associatedProcessorGroup (ticket #393)
**          03/18/2007 grk - make @associatedProcessorGroup viable for reset mode (ticket #418)
**          05/07/2007 grk - corrected spelling of sproc name
**          02/29/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUserMultiID (Ticket #644)
**          03/14/2008 grk - Fixed problem with null arguments (Ticket #655)
**          04/09/2008 mem - Now calling AlterEnteredByUserMultiID if the jobs are associated with a processor group
**          07/11/2008 jds - Added 5 new fields (@paramFileName, @settingsFileName, @organismID, @protCollNameList, @protCollOptionsList)
**                           and code to validate param file settings file against tool type
**          10/06/2008 mem - Now updating parameter file name, settings file name, protein collection list, protein options list, and organism when a job is reset (for any of these that are not '[no change]')
**          11/05/2008 mem - Now allowing for find/replace in comments when @mode = 'reset'
**          02/27/2009 mem - Changed default values to [no change]
**                           Expanded update failure messages to include more detail
**                           Expanded @comment to varchar(512)
**          03/12/2009 grk - Removed [no change] from @associatedProcessorGroup to allow dissasociation of jobs with groups
**          07/16/2009 mem - Added missing rollback transaction statements when verifying @associatedProcessorGroup
**          09/16/2009 mem - Extracted code from UpdateAnalysisJobs
**                         - Added parameter @disableRaiseError
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          03/30/2015 mem - Tweak warning message grammar
**          05/28/2015 mem - No longer updating processor group entries (thus @associatedProcessorGroup is ignored)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand @organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**
*****************************************************/
(
    @state varchar(32) = '[no change]',
    @priority varchar(12) = '[no change]',
    @comment varchar(512) = '[no change]',                    -- Text to append to the comment
    @findText varchar(255) = '[no change]',                    -- Text to find in the comment; ignored if '[no change]'
    @replaceText varchar(255) = '[no change]',                -- The replacement text when @findText is not '[no change]'
    @assignedProcessor varchar(64) = '[no change]',
    @associatedProcessorGroup varchar(64) = '',                -- Processor group; deprecated in May 2015
    @propagationMode varchar(24) = '[no change]',
--
    @paramFileName varchar(255) = '[no change]',
    @settingsFileName varchar(255) = '[no change]',
    @organismName varchar(128) = '[no change]',
    @protCollNameList varchar(4000) = '[no change]',
    @protCollOptionsList varchar(256) = '[no change]',
--
    @mode varchar(12) = 'update',            -- 'update' or 'reset' to change data; otherwise, will simply validate parameters
    @message varchar(512) output,
    @callingUser varchar(128) = '',
    @disableRaiseError tinyint = 0
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @noChangeText varchar(32) = '[no change]'
    Set @message = ''

    Declare @msg varchar(512)
    Declare @list varchar(1024)

    Declare @alterEventLogRequired tinyint
    Declare @alterEnteredByRequired tinyint
    Set @alterEventLogRequired = 0
    Set @alterEnteredByRequired = 0

    Declare @alterData tinyint
    Declare @jobCountToUpdate int
    Declare @jobCountUpdated int
    Declare @processorGroupAssociationsUpdated tinyint

    Declare @action varchar(256)
    Declare @action2 varchar(256)

    Set @alterData = 0
    Set @jobCountUpdated = 0
    Set @processorGroupAssociationsUpdated = 0

    Set @action = ''
    Set @action2 = ''
    Set @message = ''


    Declare @stateID int
    Declare @newPriority int
    Set @stateID = 0
    Set @newPriority = 2

    Declare @transName varchar(32)
    Set @transName = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateAnalysisJobsWork', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Clean up null arguments
    ---------------------------------------------------

    Set @state = LTrim(RTrim(Coalesce(@state, @noChangeText)))
    Set @priority = LTrim(RTrim(Coalesce(@priority, @noChangeText)))
    Set @comment = LTrim(RTrim(Coalesce(@comment, @noChangeText)))
    Set @findText = LTrim(RTrim(Coalesce(@findText, @noChangeText)))
    Set @replaceText = LTrim(RTrim(Coalesce(@replaceText, @noChangeText)))
    Set @assignedProcessor = LTrim(RTrim(Coalesce(@assignedProcessor, @noChangeText)))
    Set @associatedProcessorGroup = LTrim(RTrim(Coalesce(@associatedProcessorGroup, '')))
    Set @propagationMode = LTrim(RTrim(Coalesce(@propagationMode, @noChangeText)))
    Set @paramFileName = LTrim(RTrim(Coalesce(@paramFileName, @noChangeText)))
    Set @settingsFileName = LTrim(RTrim(Coalesce(@settingsFileName, @noChangeText)))
    Set @organismName = LTrim(RTrim(Coalesce(@organismName, @noChangeText)))
    Set @protCollNameList = LTrim(RTrim(Coalesce(@protCollNameList, @noChangeText)))
    Set @protCollOptionsList = LTrim(RTrim(Coalesce(@protCollOptionsList, @noChangeText)))

    Set @callingUser = LTrim(RTrim(Coalesce(@callingUser, '')))
    Set @disableRaiseError = Coalesce(@disableRaiseError, 0)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    if (@findText = @noChangeText and @replaceText <> @noChangeText) OR (@findText <> @noChangeText and @replaceText = @noChangeText)
    begin
        Set @msg = 'The Find In Comment and Replace In Comment enabled flags must both be enabled or disabled'
        if @disableRaiseError = 0
            RAISERROR (@msg, 10, 1)
        else
            Set @message = @msg
        return 51001
    end

     ---------------------------------------------------
    -- Verify that all jobs exist
    ---------------------------------------------------
    --
    Set @list = ''
    --
    SELECT
        @list = @list + CASE
        WHEN @list = '' THEN cast(Job as varchar(12))
        ELSE ', ' + cast(Job as varchar(12))
        END
    FROM
        #TAJ
    WHERE
        NOT Job IN (SELECT AJ_jobID FROM T_Analysis_Job)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @message = 'Error checking job existence'
        return 51007
    end
    --
    if @list <> ''
    begin
        Set @message = 'The following jobs were not in the database: "' + @list + '"'
        return 51007
    end


    ---------------------------------------------------
    -- Define the job counts and initialize the action text
    ---------------------------------------------------

    SELECT @jobCountToUpdate = COUNT(*) FROM #TAJ

    ---------------------------------------------------
    -- Resolve state name
    ---------------------------------------------------
    --
    if @state <> @noChangeText
    begin
        --
        SELECT @stateID = AJS_stateID
        FROM  T_Analysis_State_Name
        WHERE (AJS_name = @state)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            Set @msg = 'Error looking up state name'
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
            return 51007
        end
        --
        if @stateID = 0
        begin
            Set @msg = 'State name not found: "' + @state + '"'
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
            return 51007
        end
    end -- if @state


    ---------------------------------------------------
    -- Resolve organism ID
    ---------------------------------------------------
    --
    Declare @orgid int = 0
    --
    if @organismName <> @noChangeText
    begin
        SELECT @orgid = ID
        FROM V_Organism_List_Report
        WHERE (Name = @organismName)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            Set @msg = 'Error trying to resolve organism name'
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
            return 51014
        end
        --
        if @orgid = 0
        begin
            Set @msg = 'Organism name not found: "' + @organismName + '"'
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
            return 51015
        end
    end

    ---------------------------------------------------
    -- Validate param file for tool
    ---------------------------------------------------
    Declare @result int
    --
    Set @result = 0
    --
    if @paramFileName <> @noChangeText
    begin
        SELECT @result = Param_File_ID
        FROM T_Param_Files
        WHERE Param_File_Name = @paramFileName
        --
        if @result = 0
        begin
            Set @message = 'Parameter file could not be found' + ':"' + @paramFileName + '"'
            return 51016
        end
    end

    ---------------------------------------------------
    -- Validate parameter file for tool
    ---------------------------------------------------
    --
    if @paramFileName <> @noChangeText
    begin
        Declare @comma_list as varchar(4000)
        Declare @id as varchar(32)
        Set @comma_list = ''

        Declare cma_list_cursor CURSOR
        FOR SELECT TD.Job
            FROM #TAJ TD
            WHERE not exists (
                SELECT AJ.AJ_jobID
                FROM dbo.T_Param_Files PF
                    INNER JOIN T_Analysis_Tool AnTool
                        ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType
                    JOIN T_Analysis_Job AJ
                        ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
                WHERE (PF.Valid = 1)
                AND PF.Param_File_Name = @paramFileName
                AND AJ.AJ_jobID = TD.Job
                )
        OPEN cma_list_cursor

        FETCH NEXT FROM cma_list_cursor INTO @id

        WHILE @@fETCH_STATUS = 0
        BEGIN

            Set @comma_list = @comma_list + @id + ','

        FETCH NEXT FROM cma_list_cursor INTO @id

        END

        CLOSE cma_list_cursor
        DEALLOCATE cma_list_cursor

        if @comma_list <> ''
        begin
            Set @message = 'Based on the parameter file entered, the following Analysis Job(s) were not compatible with the the tool type' + ':"' + @comma_list + '"'
            return 51017
        end
    end

    ---------------------------------------------------
    -- Validate settings file for tool
    ---------------------------------------------------
    --
    if @settingsFileName <> @noChangeText
    begin
        -- Validate settings file for tool only
        --
        Declare @sf_comma_list as varchar(4000)
        Declare @sf_id as varchar(32)
        Set @sf_comma_list = ''

        Declare cma_list_cursor CURSOR
        FOR SELECT TD.Job
            FROM #TAJ TD
            WHERE not exists (
                SELECT AJ.AJ_jobID
                FROM dbo.T_Settings_Files SF
                    INNER JOIN T_Analysis_Tool AnTool
                        ON SF.Analysis_Tool = AnTool.AJT_toolName
                    JOIN T_Analysis_Job AJ
                        ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
                WHERE SF.File_Name = @settingsFileName
                AND AJ.AJ_jobID = TD.Job
                )
        OPEN cma_list_cursor

        FETCH NEXT FROM cma_list_cursor INTO @sf_id

        WHILE @@fETCH_STATUS = 0
        BEGIN

            Set @sf_comma_list = @sf_comma_list + @sf_id + ','

        FETCH NEXT FROM cma_list_cursor INTO @sf_id

        END

        CLOSE cma_list_cursor
        DEALLOCATE cma_list_cursor

        if @sf_comma_list <> ''
        begin
            Set @message = 'Based on the settings file entered, the following Analysis Job(s) were not compatible with the the tool type' + ':"' + @sf_comma_list + '"'
            return 51019
        end

    end

     ---------------------------------------------------
    -- Update jobs from temporary table
    -- in cases where parameter has changed
    ---------------------------------------------------
    --
    if @mode = 'update'
    begin -- <update mode>
        Set @myError = 0
        Set @alterData = 1

        ---------------------------------------------------
        Set @transName = 'UpadateAnalysisJobs'
        begin transaction @transName

        -----------------------------------------------
        if @state <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_StateID = @stateID
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) And AJ_StateID <> @stateID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed when updating job state'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51004
            end

            Set @alterEventLogRequired = 1

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Update state to ' + Convert(varchar(12), @stateID)
        end

        -----------------------------------------------
        if @priority <> @noChangeText
        begin
            Set @newPriority = cast(@priority as int)

            UPDATE T_Analysis_Job
            Set
                AJ_priority = @newPriority
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND AJ_priority <> @newPriority
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed when updating job priority'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51004
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Update priority to ' + Convert(varchar(12), @newPriority)
        end

        -----------------------------------------------
        if @comment <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_comment = AJ_comment + ' ' + @comment
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed when appending new comment text'
                rollback transaction @transName
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
                return 51004
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Append comment text'
        end

        -----------------------------------------------
        if @findText <> @noChangeText and @replaceText <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_comment = replace(AJ_comment, @findText, @replaceText)
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed when finding and replacing text in comment'
                rollback transaction @transName
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
                return 51004
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Replace comment text'
        end

        -----------------------------------------------
        if @assignedProcessor <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_assignedProcessorName =  @assignedProcessor
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND AJ_assignedProcessorName <> @assignedProcessor
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at assigned processor name update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51004
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Update assigned processor to ' + @assignedProcessor
        end

        -----------------------------------------------
        if @propagationMode <> @noChangeText
        begin
            Declare @propMode smallint
            Set @propMode = CASE @propagationMode
                                WHEN 'Export' THEN 0
                                WHEN 'No Export' THEN 1
                                ELSE 0
                            END
            --
            UPDATE T_Analysis_Job
            Set
                AJ_propagationMode =  @propMode
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND AJ_propagationMode <> @propMode
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at propagation mode update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51009
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Update propagation mode to ' + @propagationMode
        end

        -----------------------------------------------
        if @paramFileName <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_parmFileName =  @paramFileName
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND aj_parmFileName <> '@paramFileName'
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at parameter file name update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51010
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Update parameter file to ' + @paramFileName
        end

        -----------------------------------------------
        if @settingsFileName <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set AJ_settingsFileName =  @settingsFileName
            WHERE AJ_jobID in (SELECT Job FROM #TAJ) AND
                  AJ_settingsFileName <> @settingsFileName
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at settings file name update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51011
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Update settings file to ' + @settingsFileName
        end

        -----------------------------------------------
        if @organismName <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_organismID =  @orgid
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND AJ_organismID <> @orgid
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at organism name update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51012
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Change organism to ' + @organismName
        end

        -----------------------------------------------
        if @protCollNameList <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_proteinCollectionList = @protCollNameList
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND AJ_proteinCollectionList <> @protCollNameList
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at protein collection update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51013
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Change protein collection list to ' + @protCollNameList
        end

        -----------------------------------------------
        if @protCollOptionsList <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_proteinOptionsList =  @protCollOptionsList
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ)) AND AJ_proteinOptionsList <> @protCollOptionsList
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed and protein collection options update'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51014
            end

            Set @jobCountUpdated = @myRowCount
            Set @action = 'Change protein options list to ' + @protCollOptionsList
        end

    end -- </update mode>

     ---------------------------------------------------
    -- Reset job to New state
    ---------------------------------------------------
    --
    if @mode = 'reset'
    begin -- <reset mode>

        Set @alterData = 1

        ---------------------------------------------------
        Set @transName = 'UpadateAnalysisJobs'
        begin transaction @transName
        Set @myError = 0

        Set @stateID = 1

        UPDATE T_Analysis_Job
        Set
            AJ_StateID = @stateID,
            AJ_start = NULL,
            AJ_finish = NULL,
            AJ_resultsFolderName = '',
            AJ_extractionProcessor = '',
            AJ_extractionStart = NULL,
            AJ_extractionFinish = NULL,
            AJ_parmFileName = CASE WHEN @paramFileName = @noChangeText              THEN AJ_parmFileName ELSE @paramFileName END,
            AJ_settingsFileName = CASE WHEN @settingsFileName = @noChangeText       THEN AJ_settingsFileName ELSE @settingsFileName END,
            AJ_proteinCollectionList = CASE WHEN @protCollNameList = @noChangeText  THEN AJ_proteinCollectionList ELSE @protCollNameList END,
            AJ_proteinOptionsList = CASE WHEN @protCollOptionsList = @noChangeText  THEN AJ_proteinOptionsList ELSE @protCollOptionsList END,
            AJ_organismID = CASE WHEN @organismName = @noChangeText                 THEN AJ_organismID ELSE @orgid END,
            AJ_priority =  CASE WHEN @priority = @noChangeText                      THEN AJ_priority ELSE CAST(@priority AS int) END,
            AJ_comment = AJ_comment + CASE WHEN @comment = @noChangeText            THEN '' ELSE ' ' + @comment END,
            AJ_assignedProcessorName = CASE WHEN @assignedProcessor = @noChangeText THEN AJ_assignedProcessorName ELSE @assignedProcessor END
        WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            Set @msg = 'Update operation failed at bulk job info update for reset jobs'
            rollback transaction @transName
            if @disableRaiseError = 0
                RAISERROR (@msg, 10, 1)
            else
                Set @message = @msg
            return 51004
        end

        Set @jobCountUpdated = @myRowCount
        Set @action = 'Reset job state'

        If @paramFileName <> @noChangeText
            Set @action2 = @action2 + '; changed param file to ' + @paramFileName

        If @settingsFileName <> @noChangeText
            Set @action2 = @action2 + '; changed settings file to ' + @settingsFileName

        If @protCollNameList <> @noChangeText
            Set @action2 = @action2 + '; changed protein collection to ' + @protCollNameList

        If @protCollOptionsList <> @noChangeText
            Set @action2 = @action2 + '; changed protein options to ' + @protCollOptionsList

        If @organismName <> @noChangeText
            Set @action2 = @action2 + '; changed organism name to ' + @organismName

        If @priority <> @noChangeText
            Set @action2 = @action2 + '; changed priority to ' + @priority

        If @comment <> @noChangeText
            Set @action2 = @action2 + '; appended comment text'

        If @assignedProcessor <> @noChangeText
            Set @action2 = @action2 + '; updated assigned processor to ' + @assignedProcessor

        -----------------------------------------------
        if @findText <> @noChangeText and @replaceText <> @noChangeText
        begin
            UPDATE T_Analysis_Job
            Set
                AJ_comment = replace(AJ_comment, @findText, @replaceText)
            WHERE (AJ_jobID in (SELECT Job FROM #TAJ))
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed at comment find/replace for reset jobs'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51004
            end

            If @assignedProcessor <> @noChangeText
                Set @action2 = @action2 + '; replaced text in comment'

        end

        Set @alterEventLogRequired = 1
    end -- </reset mode>

     /*
    ---------------------------------------------------
    -- Deprecated in May 2015:
    -- Handle associated processor Group
    -- (though only if we're actually performing an update or reset)
    --
    if @associatedProcessorGroup <> @noChangeText and @transName <> ''
    begin -- <associated processor group>

        ---------------------------------------------------
        -- Resolve processor group ID
        --
        Declare @gid int
        Set @gid = 0
        --
        if @associatedProcessorGroup <> ''
        begin
            SELECT @gid = ID
            FROM T_Analysis_Job_Processor_Group
            WHERE (Group_Name = @associatedProcessorGroup)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Error trying to resolve processor group name'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51008
            end
            --
            if @gid = 0
            begin
                Set @msg = 'Processor group name not found: "' + @associatedProcessorGroup + '"'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51009
            end
        end

        if @gid = 0
        begin
            -- Dissassociate given jobs from group
            --
            DELETE FROM T_Analysis_Job_Processor_Group_Associations
            WHERE (Job_ID in (SELECT Job FROM #TAJ))
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed removing job from processor group association'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51014
            end

            If @jobCountUpdated = 0
                Set @jobCountUpdated = @myRowCount

            Set @action2 = @action2 + '; remove jobs from processor group'
        end
        else
        begin
            -- For jobs with existing association, change it
            --
            UPDATE T_Analysis_Job_Processor_Group_Associations
            Set    Group_ID = @gid,
                Entered = GetDate(),
                Entered_By = suser_sname()
            WHERE (Job_ID in (SELECT Job FROM #TAJ)) AND Group_ID <> @gid
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed changing job to processor group association'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51015
            end

            If @myRowCount <> 0
                Set @processorGroupAssociationsUpdated = 1

            -- For jobs without existing association, create it
            --
            INSERT INTO T_Analysis_Job_Processor_Group_Associations
                                (Job_ID, Group_ID)
            SELECT Job, @gid FROM #TAJ
            WHERE NOT (Job IN (SELECT Job_ID FROM T_Analysis_Job_Processor_Group_Associations))
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                Set @msg = 'Update operation failed assigning job to new processor group association'
                rollback transaction @transName
                if @disableRaiseError = 0
                    RAISERROR (@msg, 10, 1)
                else
                    Set @message = @msg
                return 51016
            end

            If @jobCountUpdated = 0
                Set @jobCountUpdated = @myRowCount

            If @myRowCount <> 0 OR @processorGroupAssociationsUpdated <> 0
                Set @action2 = @action2 + '; associate jobs with processor group ' + @associatedProcessorGroup

            Set @alterEnteredByRequired = 1
        end
    end  -- </associated processor Group>
    */

     If Len(@callingUser) > 0 AND (@alterEventLogRequired <> 0 OR @alterEnteredByRequired <> 0)
    Begin
        -- @callingUser is defined and items need to be updated in T_Event_Log and/or T_Analysis_Job_Processor_Group_Associations
        --
        -- Populate a temporary table with the list of Job IDs just updated
        CREATE TABLE #TmpIDUpdateList (
            TargetID int NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

        INSERT INTO #TmpIDUpdateList (TargetID)
        SELECT DISTINCT Job
        FROM #TAJ

        If @alterEventLogRequired <> 0
        Begin
            -- Call AlterEventLogEntryUserMultiID
            -- to alter the Entered_By field in T_Event_Log

            Exec AlterEventLogEntryUserMultiID 5, @stateID, @callingUser
        End

        If @alterEnteredByRequired <> 0
        Begin
            -- Call AlterEnteredByUserMultiID
            -- to alter the Entered_By field in T_Analysis_Job_Processor_Group_Associations

            Exec AlterEnteredByUserMultiID 'T_Analysis_Job_Processor_Group_Associations', 'Job_ID', @callingUser
        End
    End


     ---------------------------------------------------
    -- Finalize the changes
    ---------------------------------------------------
    if @transName <> ''
    begin
        commit transaction @transName
    end

    Set @message = 'Number of jobs to update: ' + convert(varchar(12), @jobCountToUpdate)

    If @alterData <> 0
    Begin
        If @jobCountUpdated = 0
        Begin
            If @action = ''
                Set @message = 'No parameters were specified to be updated (' + @message + ')'
            Else
                Set @message = @message + '; all jobs were already up-to-date (' + @action + ')'
        End
        else
            Set @message = @message + '; ' + @action + ' for ' +  convert(varchar(12), @jobCountUpdated) + ' job(s)' + @action2
    End


    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobsWork] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobsWork] TO [Limited_Table_Write] AS [dbo]
GO
