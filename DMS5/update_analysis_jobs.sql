/****** Object:  StoredProcedure [dbo].[UpdateAnalysisJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateAnalysisJobs]
/****************************************************
**
**  Desc:
**   Updates parameters to new values for jobs in list
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/06/2006
**          04/10/2006 grk - widened size of list argument to 6000 characters
**          04/12/2006 grk - eliminated forcing null for blank assigned processor
**          06/20/2006 jds - added support to find/replace text in the comment field
**          08/02/2006 grk - clear the AJ_ResultsFolderName, AJ_extractionProcessor,
**                           AJ_extractionStart, and AJ_extractionFinish fields when resetting a job
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
**          09/16/2009 mem - Expanded @JobList to varchar(max)
**                         - Now calls UpdateAnalysisJobsWork to do the work
**          08/19/2010 grk - try-catch for error handling
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand @organismName to varchar(128)
**          06/30/2022 mem - Rename parameter file argument
**
*****************************************************/
(
    @JobList varchar(max),
    @state varchar(32) = '[no change]',
    @priority varchar(12) = '[no change]',
    @comment varchar(512) = '[no change]',          -- Text to append to the comment
    @findText varchar(255) = '[no change]',         -- Text to find in the comment; ignored if '[no change]'
    @replaceText varchar(255) = '[no change]',      -- The replacement text when @findText is not '[no change]'
    @assignedProcessor varchar(64) = '[no change]',
    @associatedProcessorGroup varchar(64) = '',
    @propagationMode varchar(24) = '[no change]',
--
    @paramFileName varchar(255) = '[no change]',
    @settingsFileName varchar(64) = '[no change]',
    @organismName varchar(128) = '[no change]',
    @protCollNameList varchar(4000) = '[no change]',
    @protCollOptionsList varchar(256) = '[no change]',
--
    @mode varchar(12) = 'update',           -- 'update' or 'reset' to change data; otherwise, will simply validate parameters
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)
    Declare @JobCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateAnalysisJobs', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    BEGIN TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    if IsNull(@JobList, '') = ''
    begin
        Set @msg = 'Job list is empty'
        RAISERROR (@msg, 11, 1)
    end

    ---------------------------------------------------
    --  Create temporary table to hold list of jobs
    ---------------------------------------------------

    CREATE TABLE #TAJ (
        Job int
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @msg = 'Failed to create temporary job table'
        RAISERROR (@msg, 11, 2)
    end

    ---------------------------------------------------
    -- Populate table from job list
    ---------------------------------------------------

    INSERT INTO #TAJ
    (Job)
    SELECT DISTINCT Convert(int, Item)
    FROM MakeTableFromList(@JobList)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @msg = 'Error populating temporary job table'
        RAISERROR (@msg, 11, 3)
    end

    Set @JobCount = @myRowCount

    ---------------------------------------------------
    -- Call UpdateAnalysisJobs to do the work
    -- It uses #TAJ to determine which jobs to update
    ---------------------------------------------------

    exec @myError = UpdateAnalysisJobsWork
                        @state,
                        @priority,
                        @comment,
                        @findText,
                        @replaceText,
                        @assignedProcessor,
                        @associatedProcessorGroup,
                        @propagationMode,
                        @paramFileName,
                        @settingsFileName,
                        @organismName,
                        @protCollNameList,
                        @protCollOptionsList,
                        @mode,
                        @msg output,
                        @callingUser
    if @myError <> 0
    begin
        RAISERROR (@msg, 11, 5)
    end

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'UpdateAnalysisJobs'
    END CATCH

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @UsageMessage varchar(512)
    Set @UsageMessage = Convert(varchar(12), @JobCount) + ' jobs updated'
    Exec PostUsageLogEntry 'UpdateAnalysisJobs', @UsageMessage

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobs] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobs] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateAnalysisJobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateAnalysisJobs] TO [RBAC-Web_Analysis] AS [dbo]
GO
