/****** Object:  StoredProcedure [dbo].[update_instrument_usage_allocations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_instrument_usage_allocations]
/****************************************************
**
**  Desc:
**      Update requested instrument usage allocation via specific parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/28/2012 grk - Initial release
**          03/30/2012 grk - Added change command capability
**          03/30/2012 mem - Added support for x="Comment" in the XML
**                         - Now calling update_instrument_usage_allocations_work to apply the updates
**          03/31/2012 mem - Added @FiscalYear, @ProposalID, and @mode
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @fyProposal varchar(64),            -- Only used when @mode is 'update'
    @fiscalYear varchar(24),            -- Only used when @mode is 'add'
    @proposalID varchar(128),            -- Only used when @mode is 'add'
    @ft varchar(24) = '',
    @ftComment varchar(256) = '',
    @ims varchar(24) = '',
    @imsComment varchar(256) = '',
    @orb varchar(24) = '',
    @orbComment varchar(256) = '',
    @exa varchar(24) = '',
    @exaComment varchar(256) = '',
    @ltq varchar(24) = '',
    @ltqComment varchar(256) = '',
    @gc varchar(24) = '',
    @gcComment varchar(256) = '',
    @qqq varchar(24) = '',
    @qqqComment varchar(256) = '',
    @mode varchar(12) = 'update',    -- 'add' or 'update'
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0                    -- Set to 1 to preview the changes that would be made
)
AS
    Set XACT_ABORT, nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Declare @fy int

    Declare @CharIndex int

    Declare @Msg2 varchar(512)

    DECLARE @xml AS xml
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_PADDING ON

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_instrument_usage_allocations', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

        -----------------------------------------------------------
        -- Validate the inputs
        -----------------------------------------------------------

        Set @FYProposal = IsNull(@FYProposal, '')
        Set @FiscalYear = IsNull(@FiscalYear, '')
        Set @ProposalID = IsNull(@ProposalID, '')

        Set @FT = IsNull(@FT, '')
        Set @IMS = IsNull(@IMS, '')
        Set @ORB = IsNull(@ORB, '')
        Set @EXA = IsNull(@EXA, '')
        Set @LTQ = IsNull(@LTQ, '')
        Set @GC = IsNull(@GC, '')
        Set @QQQ = IsNull(@QQQ, '')

        Set @FTComment = IsNull(@FTComment, '')
        Set @IMSComment = IsNull(@IMSComment, '')
        Set @ORBComment = IsNull(@ORBComment, '')
        Set @EXAComment = IsNull(@EXAComment, '')
        Set @LTQComment = IsNull(@LTQComment, '')
        Set @GCComment = IsNull(@GCComment,  '')
        Set @QQQComment = IsNull(@QQQComment, '')

        SET @message = ''
        Set @infoOnly = IsNull(@infoOnly, 0)


        If Not @mode in ('add', 'update')
        Begin
            Set @Msg2 = 'Invalid mode: ' + IsNull(@mode, '??')
            RAISERROR (@Msg2, 11, 1)
        End

        If @mode = 'add'
        Begin
            If @FiscalYear = ''
                RAISERROR ('Fiscal Year is empty; cannot add', 11, 1)

            If @ProposalID = ''
                RAISERROR ('Proposal ID is empty; cannot add', 11, 1)

            If Exists (SELECT * FROM T_Instrument_Allocation WHERE Proposal_ID = @ProposalID AND Fiscal_Year = @FiscalYear)
            Begin
                Set @Msg2 = 'Existing entry already exists, cannot add: ' + @FiscalYear + '_' + @ProposalID
                RAISERROR (@Msg2, 11, 1)
            End

        End

        If @mode = 'update'
        Begin
            If @FYProposal = ''
                RAISERROR ('@FYProposal parameter is empty', 11, 1)

            -- Split @FYProposal into @FiscalYear and @ProposalID
            Set @CharIndex = CharIndex('_', @FYProposal)
            If @CharIndex <= 1 Or @CharIndex = Len(@FYProposal)
                RAISERROR ('@FYProposal parameter is not in the correct format', 11, 1)

            Declare @FiscalYearParam varchar(24)
            Declare @ProposalIDParam varchar(128)
            Set @FiscalYearParam = @FiscalYear
            Set @ProposalIDParam = @ProposalID

            Set @FiscalYear = Substring(@FYProposal, 1, @CharIndex-1)
            Set @ProposalID = Substring(@FYProposal, @CharIndex+1, 128)

            If Not Exists (SELECT * FROM T_Instrument_Allocation WHERE FY_Proposal = @FYProposal)
            Begin
                Set @Msg2 = 'Entry not found, unable to update: ' + @FYProposal
                RAISERROR (@Msg2, 11, 1)
            End

            If Not Exists (SELECT * FROM T_Instrument_Allocation WHERE FY_Proposal = @FYProposal AND Proposal_ID = @ProposalID AND Fiscal_Year = @FiscalYear)
            Begin
                Set @Msg2 = 'Mismatch between FY_Proposal, FiscalYear, and ProposalID: ' + @FYProposal + ' vs. ' + @FiscalYear + ' vs. ' + @ProposalID
                RAISERROR (@Msg2, 11, 1)
            End

            If ISNULL(@FiscalYearParam, '') <> '' And @FiscalYearParam <> @FiscalYear
            Begin
                Set @Msg2 = 'Cannot change FiscalYear when updating: ' + @FiscalYear + ' vs. ' + @FiscalYearParam
                RAISERROR (@Msg2, 11, 1)
            End

            If ISNULL(@ProposalIDParam, '') <> '' And @ProposalIDParam <> @ProposalID
            Begin
                Set @Msg2 = 'Cannot change ProposalID when updating: ' + @ProposalID + ' vs. ' + @ProposalIDParam
                RAISERROR (@Msg2, 11, 1)
            End
        End

        -- Validate @ProposalID
        If Not Exists (SELECT * FROM T_EUS_Proposals WHERE PROPOSAL_ID = @ProposalID)
        Begin
            Set @Msg2 = 'Invalid EUS ProposalID: ' + @ProposalID
            RAISERROR (@Msg2, 11, 1)
        End


        -----------------------------------------------------------
        -- temp table to hold operations
        -----------------------------------------------------------
        --
        CREATE TABLE #T_OPS (
            Entry_ID int Identity(1,1),
            Allocation varchar(128) NULL,
            InstGroup varchar(128) null,
            Proposal varchar(128) null,
            Comment varchar(256) null,
            FY int,
            Operation CHAR(1) NULL -- 'i' -> increment, 'd' -> decrement, anything else -> set
        )


        Set @fy = Try_Parse(@FiscalYear as int)
        If @fy Is Null Or @fy = 0
        Begin
            Set @Msg2 = 'Fiscal year is not numeric: ' + @FiscalYear
            RAISERROR (@Msg2, 11, 1)
        End

        If @FT <> ''
        Begin
            Declare @FThours float = Try_Parse(@FT as float)
            If @FThours Is Null
            Begin
                Set @Msg2 = 'FT hours is not numeric: ' + @FT
                RAISERROR (@Msg2, 11, 1)
            End
            Else
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'FT', @FThours, @FTComment, @FY)
        End

        If @IMS <> ''
        Begin
            Declare @IMShours float = Try_Parse(@IMS as float)
            If @IMShours Is Null
            Begin
                Set @Msg2 = 'IMS hours is not numeric: ' + @IMS
                RAISERROR (@Msg2, 11, 1)
            End
            Else
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'IMS', @IMShours, @IMSComment, @FY)
        End

        If @ORB <> ''
        Begin
            Declare @ORBhours float = Try_Parse(@ORB as float)
            If @ORBhours Is Null
            Begin
                Set @Msg2 = 'Orbitrap hours is not numeric: ' + @ORB
                RAISERROR (@Msg2, 11, 1)
            End
            Else
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'ORB', @ORBhours, @ORBComment, @FY)
        End

        If @EXA <> ''
        Begin
            Declare @EXAhours float = Try_Parse(@EXA as float)
            If @EXAhours Is Null
            Begin
                Set @Msg2 = 'Exactive hours is not numeric: ' + @EXA
                RAISERROR (@Msg2, 11, 1)
            End
            Else
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'EXA', @EXAhours, @EXAComment, @FY)
        End

        If @LTQ <> ''
        Begin
            Declare @LTQhours float = Try_Parse(@LTQ as float)
            If @LTQhours Is Null
            Begin
                Set @Msg2 = 'LTQ hours is not numeric: ' + @LTQ
                RAISERROR (@Msg2, 11, 1)
            End
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'LTQ', @LTQhours, @LTQComment, @FY)
        End

        If @GC <> ''
        Begin
            Declare @GChours float = Try_Parse(@GC as float)
            If @GChours Is Null
            Begin
                Set @Msg2 = 'GC hours is not numeric: ' + @GC
                RAISERROR (@Msg2, 11, 1)
            End
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'GC', @GChours, @GCComment, @FY)
        End

        If @QQQ <> ''
        Begin
            Declare @QQQhours float = Try_Parse(@QQQ as float)
            If @QQQhours Is Null
            Begin
                Set @Msg2 = 'QQQ hours is not numeric: ' + @QQQ
                RAISERROR (@Msg2, 11, 1)
            End
                INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
                VALUES ('',  @ProposalID, 'QQQ', @QQQhours, @QQQComment, @FY)
        End

        -----------------------------------------------------------
        -- Call update_instrument_usage_allocations_work to perform the work
        -----------------------------------------------------------
        --
        EXEC @myError = update_instrument_usage_allocations_work @fy, @message output, @callingUser, @infoOnly

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'update_instrument_usage_allocations'
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_instrument_usage_allocations] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_instrument_usage_allocations] TO [DMS2_SP_User] AS [dbo]
GO
