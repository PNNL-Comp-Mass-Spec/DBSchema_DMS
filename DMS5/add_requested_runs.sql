/****** Object:  StoredProcedure [dbo].[add_requested_runs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_requested_runs]
/****************************************************
**
**  Desc:
**      Adds a group of entries to the requested run table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/22/2005 - Initial version
**          07/27/2005 grk - modified prefix
**          10/12/2005 grk - Added stuff for new work package and proposal fields.
**          02/23/2006 grk - Added stuff for EUS proposal and user tracking.
**          03/24/2006 grk - Added stuff for auto incrementing well numbers.
**          06/23/2006 grk - Removed instrument name from generated request name
**          10/12/2006 grk - Fixed trailing suffix in name (Ticket #248)
**          11/09/2006 grk - Fixed error message handling (Ticket #318)
**          07/17/2007 grk - Increased size of comment field (Ticket #500)
**          09/06/2007 grk - Removed @specialInstructions (http://prismtrac.pnl.gov/trac/ticket/522)
**          04/25/2008 grk - Added secondary separation field (Ticket #658)
**          03/26/2009 grk - Added MRM transition list attachment (Ticket #727)
**          07/27/2009 grk - removed autonumber for well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          03/02/2010 grk - added status field to requested run
**          08/27/2010 mem - Now referring to @instrumentGroup as an instrument group
**          09/29/2011 grk - fixed limited size of variable holding delimited list of experiments from group
**          12/14/2011 mem - Added parameter @callingUser, which is passed to add_update_requested_run
**          02/20/2012 mem - Now using a temporary table to track the experiment names for which requested runs need to be created
**          02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**          06/13/2013 mem - Added @vialingConc and @vialingVol
                           - Now validating @workPackageNumber against T_Charge_Code
**          06/18/2014 mem - Now passing default to parse_delimited_list
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/19/2017 mem - Use @logErrors to toggle logging errors caught by the try/catch block
**          06/13/2017 mem - Rename @operatorUsername to @requestorUsername when calling add_update_requested_run
**          12/12/2017 mem - Add @stagingLocation (points to T_Material_Locations)
**          05/29/2021 mem - Add parameters to allow also creating a batch
**          06/01/2021 mem - Show names of the new requests when previewing updates
**          07/01/2021 mem - Rename instrument parameter to be @instrumentGroup
**                         - Add parameters @batchPriorityJustification and @batchComment
**          07/09/2021 mem - Fix bug handling instrument group name when @batchName is blank
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/17/2022 mem - Update operator username warning
**          05/23/2022 mem - Rename @requestorUsername to @requesterUsername when calling add_update_requested_run
**          11/25/2022 mem - Update call to add_update_requested_run to use new parameter name
**          02/14/2023 mem - Use new parameter names for validate_requested_run_batch_params
**          02/17/2023 mem - Use new parameter name when calling add_update_requested_run_batch
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/27/2023 mem - Use new argument name, @requestName
**          09/07/2023 mem - Update warning messages
**          11/27/2023 mem - Do not log errors from validate_requested_run_batch_params() if @myError is between 50000 and 50050
**          01/22/2024 mem - Remove deprecated instrument group arguments when calling validate_requested_run_batch_params() and add_update_requested_run_batch()
**
*****************************************************/
(
    @experimentGroupID varchar(12) = '',        -- Specify ExperimentGroupID or ExperimentList, but not both
    @experimentList varchar(3500) = '',
    @requestNameSuffix varchar(32) = '',        -- Actually used as the request name Suffix
    @operatorUsername varchar(64),
    @instrumentGroup varchar(64),               -- Instrument group; could also contain '(lookup)'
    @workPackage varchar(50),                   -- Work Package; could also contain '(lookup)'
    @msType varchar(20),                        -- Run type; could also contain '(lookup)'
    @instrumentSettings varchar(512) = 'na',
    @eusProposalID varchar(10) = 'na',
    @eusUsageType varchar(50),
    @eusUsersList varchar(1024) = '',           -- Comma separated list of EUS user IDs (integers); also supports the form 'Baker, Erin (41136)'
    @internalStandard varchar(50) = 'na',
    @comment varchar(1024) = 'na',
    @mode varchar(12) = 'add',                  -- or 'PreviewAdd'
    @message varchar(512) output,
    @separationGroup varchar(64) = 'LC-Formic_100min',      -- Separation group; could also contain '(lookup)'
    @mrmAttachment varchar(128),
    @vialingConc varchar(32) = null,
    @vialingVol varchar(32) = null,
    @stagingLocation varchar(64) = null,
    @batchName varchar(50) = '',                -- If defined, create a new batch for the newly created requested runs
    @batchDescription Varchar(256) = '',
    @batchCompletionDate varchar(32) = '',
    @batchPriority varchar(24) = '',
    @batchPriorityJustification varchar(512),
    @batchComment varchar(512),
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError Int = 0
    Declare @myRowCount Int = 0

    Set @message = ''

    Declare @msg varchar(256) = ''
    Declare @logErrors tinyint = 0

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @experimentGroupID = LTrim(RTrim(IsNull(@experimentGroupID, '')))
    Set @experimentList = LTrim(RTrim(IsNull(@experimentList, '')))
    Set @batchName = LTrim(RTrim(IsNull(@batchName, '')))

    If @experimentGroupID <> '' AND @experimentList <> ''
    Begin
        Set @myError = 51130
        Set @message = 'Experiment Group ID and Experiment List cannot both be non-blank'
        RAISERROR (@message, 11, 20)
    End
    --
    If @experimentGroupID = '' AND @experimentList = ''
    Begin
        Set @myError = 51131
        Set @message = 'Experiment Group ID and Experiment List cannot both be blank'
        RAISERROR (@message,11, 21)
    End
    --

    Declare @experimentGroupIDVal int
    If Len(@experimentGroupID) > 0
    Begin
        Set @experimentGroupIDVal = Try_Parse(@experimentGroupID as int)
        If @experimentGroupIDVal Is Null
        Begin
            Set @myError = 51132
            Set @message = 'Experiment Group ID must be a number: ' + @experimentGroupID
            RAISERROR (@message,11, 21)
        End
    End
    --
    If LEN(@operatorUsername) < 1
    Begin
        Set @myError = 51113
        RAISERROR ('Operator username must be specified', 11, 22)
    End
    --
    If LEN(@instrumentGroup) < 1
    Begin
        Set @myError = 51114
        RAISERROR ('Instrument group must be specified', 11, 23)
    End
    --
    If LEN(@msType) < 1
    Begin
        Set @myError = 51115
        RAISERROR ('Dataset type must be specified', 11, 24)
    End
    --
    If LEN(@workPackage) < 1
    Begin
        Set @myError = 51115
        RAISERROR ('Work package must be specified', 11, 25)
    End
    --
    If @myError <> 0
        return @myError

    ---------------------------------------------------
    -- Validate the work package
    -- This validation also occurs in add_update_requested_run but we want to validate it now before we enter the while loop
    ---------------------------------------------------

    Declare @allowNoneWP tinyint = 0

    If @workPackage <> '(lookup)'
    Begin
        exec @myError = validate_wp
                            @workPackage,
                            @allowNoneWP,
                            @msg output

        If @myError <> 0
        Begin
            RAISERROR ('validate_wp: %s', 11, 1, @msg)
        End
    End

    ---------------------------------------------------
    -- Validation checks are complete; now enable @logErrors
    ---------------------------------------------------

    Set @logErrors = 1

    ---------------------------------------------------
    -- Resolve staging location name to location ID
    ---------------------------------------------------

    Declare @locationID int = null

    If IsNull(@stagingLocation, '') <> ''
    Begin
        SELECT @locationID = ID
        FROM T_Material_Locations
        WHERE Tag = @stagingLocation
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Error trying to look up staging location ID', 11, 98)
        --
        If @locationID = 0
            RAISERROR ('Staging location not recognized', 11, 99)

    End

    ---------------------------------------------------
    -- Populate a temporary table with the experiments to process
    ---------------------------------------------------

    CREATE Table #Tmp_ExperimentsToProcess
    (
        EntryID int identity(1,1),
        Experiment varchar(256),
        RequestID Int null
    )


    If @experimentGroupID <> ''
    Begin
        ---------------------------------------------------
        -- Determine experiment names using experiment group ID
        ---------------------------------------------------

        INSERT INTO #Tmp_ExperimentsToProcess (Experiment)
        SELECT T_Experiments.Experiment_Num
        FROM T_Experiments
             INNER JOIN T_Experiment_Group_Members
               ON T_Experiments.Exp_ID = T_Experiment_Group_Members.Exp_ID
             LEFT OUTER JOIN T_Experiment_Groups
               ON T_Experiments.Exp_ID <> T_Experiment_Groups.Parent_Exp_ID
                  AND
                  T_Experiment_Group_Members.Group_ID = T_Experiment_Groups.Group_ID
        WHERE (T_Experiment_Groups.Group_ID = @experimentGroupIDVal)
        ORDER BY T_Experiments.Experiment_Num
    End
    Else
    Begin
        ---------------------------------------------------
        -- Parse @experimentList to determine experiment names
        ---------------------------------------------------

        INSERT INTO #Tmp_ExperimentsToProcess (Experiment)
        SELECT Value
        FROM dbo.parse_delimited_list(@experimentList, default, 'add_requested_runs')
        WHERE Len(Value) > 0
        ORDER BY Value
    End

    ---------------------------------------------------
    -- Set up wellplate stuff to force lookup
    -- from experiments
    ---------------------------------------------------
    --
    Declare @wellplateName varchar(64) = '(lookup)'
    Declare @wellNumber varchar(24) = '(lookup)'

    Declare @userID int

    If Len(@batchName) > 0
    Begin
        ---------------------------------------------------
        -- Validate batch fields
        ---------------------------------------------------

        Exec @myError = validate_requested_run_batch_params
                @batchID = 0,
                @name = @batchName,
                @description = @batchDescription,
                @ownerUsername = @operatorUsername,
                @requestedBatchPriority = @batchPriority,
                @requestedCompletionDate = @batchCompletionDate,
                @justificationHighPriority = @batchPriorityJustification,
                -- Deprecated in January 2024
                -- @requestedInstrumentGroup = @instrumentGroup,              -- Will typically contain an instrument group, not an instrument name
                @comment = @batchComment,
                @mode = @mode,
                -- Deprecated in January 2024
                -- @instrumentGroupToUse = @instrumentGroupToUse output,
                @userID = @userID output,
                @message = @message output

        If @myError > 0
        Begin
            -- Do not log errors to t_log_entries when @myError is between 50000 and 50050, but do raise an error so the user sees the message
            If @myError Between 50000 and 50050
            Begin
                Set @logErrors = 0
            End

            RAISERROR (@message, 11, 1)
        End
    End

    ---------------------------------------------------
    -- Step through experiments in #Tmp_ExperimentsToProcess and make
    -- a new requested run for each one
    ---------------------------------------------------

    Declare @requestName varchar(64)
    Declare @requestNameFirst varchar(64) = ''
    Declare @requestNameLast varchar(64) = ''

    Declare @request int
    Declare @experimentName varchar(64)

    Declare @suffix varchar(64) = ISNULL(@requestNameSuffix, '')

    If @suffix <> ''
    Begin
        Set @suffix = '_' + @suffix
    End

    Declare @done int = 0
    Declare @count int = 0
    Declare @entryID int = 0
    Declare @requestedRunList varchar(4000) = ''
    Declare @requestedRunMode varchar(12)

    Declare @resolvedInstrumentInfo varchar(256) = ''
    Declare @resolvedInstrumentInfoCurrent varchar(256) = ''

    If @mode = 'PreviewAdd'
        Set @requestedRunMode = 'check_add'
    Else
        Set @requestedRunMode = 'add'

    While @done = 0 and @myError = 0
    Begin

        SELECT TOP 1 @entryID = EntryID,
                     @experimentName = Experiment
        FROM #Tmp_ExperimentsToProcess
        WHERE EntryID > @entryID
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @done = 1
        End
        Else
        Begin
            Set @message = ''
            Set @requestName = @experimentName + @suffix

            If @count = 0
                Set @requestNameFirst = @requestName
            Else
                Set @requestNameLast = @requestName

            EXEC @myError = dbo.add_update_requested_run
                                    @requestName = @requestName,
                                    @experimentName = @experimentName,
                                    @requesterUsername = @operatorUsername,
                                    @instrumentName = @instrumentGroup,
                                    @workPackage = @workPackage,
                                    @msType = @msType,
                                    @instrumentSettings = @instrumentSettings,
                                    @wellplateName = @wellplateName,
                                    @wellNumber = @wellNumber,
                                    @internalStandard = @internalStandard,
                                    @comment = @comment,
                                    @eusProposalID = @eusProposalID,
                                    @eusUsageType = @eusUsageType,
                                    @eusUsersList = @eusUsersList,
                                    @mode = @requestedRunMode,
                                    @request = @request output,
                                    @message = @message output,
                                    @secSep = @separationGroup,
                                    @mrmAttachment = @mrmAttachment,
                                    @status = 'Active',
                                    @callingUser = @callingUser,
                                    @vialingConc = @vialingConc,
                                    @vialingVol = @vialingVol,
                                    @stagingLocation = @stagingLocation,
                                    @resolvedInstrumentInfo = @resolvedInstrumentInfoCurrent output
            --
            Set @message = '[' + @experimentName + '] ' + @message

            If @myError = 0 And @mode = 'add'
            Begin
                UPDATE #Tmp_ExperimentsToProcess
                SET RequestID = @request
                WHERE EntryID = @entryID

                Set @requestedRunList = @requestedRunList + Cast(@request as varchar(12)) + ', '
            End

            If @resolvedInstrumentInfo = '' And @resolvedInstrumentInfoCurrent <> ''
            Begin
                Set @resolvedInstrumentInfo = @resolvedInstrumentInfoCurrent
            End

            If @myError <> 0
            Begin
                Set @logErrors = 0
                RAISERROR (@message, 11, 1)
                Set @logErrors = 1
            End

            Set @count = @count + 1
        End
    End

    If @mode = 'PreviewAdd'
    Begin
        Set @message = 'Would create ' + cast(@count as varchar(12)) + ' requested runs (' + @requestNameFirst + ' to ' + @requestNameLast + ')'

        If @resolvedInstrumentInfo = ''
            Set @message = @message + ' with instrument group ' + @instrumentGroup + ', run type ' + @msType + ', and separation group ' + @separationGroup
        Else
            Set @message = @message + ' with ' + @resolvedInstrumentInfo
    End
    Else
    Begin
        Set @message = 'Number of requested runs created: ' + cast(@count as varchar(12))
    End

    If @myError = 0 And Len(@batchName) > 0
    Begin
        If @count <= 1
        Begin
            Set @message = dbo.append_to_text(@message, 'Not creating a batch since did not create multiple requested runs', 0, '; ', 1024)
        End
        Else
        Begin
            Declare @batchID Int = 0

            -- Auto-create a batch for the new requests
            --
            Exec @myError = add_update_requested_run_batch
                                            @id = @batchID output
                                           ,@name = @batchName
                                           ,@description = @batchDescription
                                           ,@requestedRunList = @requestedRunList
                                           ,@ownerUsername = @operatorUsername
                                           ,@requestedBatchPriority = @batchPriority
                                           ,@requestedCompletionDate = @batchCompletionDate
                                           ,@justificationHighPriority = @batchPriorityJustification
                                           -- Deprecated in January 2024
                                           -- ,@requestedInstrumentGroup = @instrumentGroupToUse
                                           ,@comment = @batchComment
                                           ,@mode = @mode
                                           ,@message = @msg output
                                           ,@useRaiseError = 0

            If @myError > 0
            Begin
                If IsNull(@msg, '') = ''
                    Set @msg = 'add_update_requested_run_batch returned error code ' + Cast(@myError As Varchar(12))
                Else
                    Set @msg = 'Error adding new batch, ' + @msg
            End
            Else
            Begin
                If @mode = 'PreviewAdd'
                    Set @msg = 'Would create a batch named "' + @batchName + '"'
                Else
                    Set @msg = 'Created batch ' + Cast(@batchID As Varchar(12))
            End

            Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
        End
    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'add_requested_runs'
        End
    END CATCH

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_requested_runs] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_requested_runs] TO [DMS_Experiment_Entry] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_requested_runs] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_requested_runs] TO [Limited_Table_Write] AS [dbo]
GO
