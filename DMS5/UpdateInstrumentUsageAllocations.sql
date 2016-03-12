/****** Object:  StoredProcedure [dbo].[UpdateInstrumentUsageAllocations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateInstrumentUsageAllocations
/****************************************************
**
**	Desc: 
**	Update requested instrument usage allocation via specific parameters
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date:	03/28/2012 grk - Initial release
**          03/30/2012 grk - Added change command capability
**			03/30/2012 mem - Added support for x="Comment" in the XML
**						   - Now calling UpdateInstrumentUsageAllocationsWork to apply the updates
**			03/31/2012 mem - Added @FiscalYear, @ProposalID, and @mode
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@FYProposal varchar(64),			-- Only used when @mode is 'update'
	@FiscalYear varchar(24),			-- Only used when @mode is 'add'
	@ProposalID varchar(128),			-- Only used when @mode is 'add'
	@FT varchar(24) = '',			
	@FTComment varchar(256) = '',	
	@IMS varchar(24) = '',			
	@IMSComment varchar(256) = '',	
	@ORB varchar(24) = '',			
	@ORBComment varchar(256) = '',	
	@EXA varchar(24) = '',			
	@EXAComment varchar(256) = '',	
	@LTQ varchar(24) = '',			
	@LTQComment varchar(256) = '',	
	@GC varchar(24) = '',			
	@GCComment varchar(256) = '',	
	@QQQ varchar(24) = '',			
	@QQQComment varchar(256) = '',	
	@mode varchar(12) = 'update',	-- 'add' or 'update'
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0					-- Set to 1 to preview the changes that would be made
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	Declare @fy int

	Declare @CharIndex int
	
	Declare @Msg2 varchar(512)
	
	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	---------------------------------------------------
	---------------------------------------------------
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
		
							
		If IsNumeric(@FiscalYear) = 0
		Begin
			Set @Msg2 = 'Fiscal year is not numeric: ' + @FiscalYear
			RAISERROR (@Msg2, 11, 1)
		End
		Else
			Set @fy = Convert(int, @FiscalYear)

		If @FT <> ''
		Begin
			If IsNumeric(@FT) = 0
			Begin
				Set @Msg2 = 'FT hours is not numeric: ' + @FT
				RAISERROR (@Msg2, 11, 1)
			End
			Else
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'FT', Convert(float, @FT), @FTComment, @FY)
		End
		
		If @IMS <> ''
		Begin
			If IsNumeric(@IMS) = 0
			Begin
				Set @Msg2 = 'IMS hours is not numeric: ' + @IMS
				RAISERROR (@Msg2, 11, 1)
			End
			Else
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'IMS', Convert(float, @IMS), @IMSComment, @FY)
		End
			
		If @ORB <> ''
		Begin
			If IsNumeric(@ORB) = 0
			Begin
				Set @Msg2 = 'Orbitrap hours is not numeric: ' + @ORB
				RAISERROR (@Msg2, 11, 1)
			End
			Else
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'ORB', Convert(float, @ORB), @ORBComment, @FY)
		End
				
		If @EXA <> ''
		Begin
			If IsNumeric(@EXA) = 0
			Begin
				Set @Msg2 = 'Exactive hours is not numeric: ' + @EXA
				RAISERROR (@Msg2, 11, 1)
			End
			Else
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'EXA', Convert(float, @EXA), @EXAComment, @FY)
		End
			
		If @LTQ <> ''
		Begin
			If IsNumeric(@LTQ) = 0
			Begin
				Set @Msg2 = 'LTQ hours is not numeric: ' + @LTQ
				RAISERROR (@Msg2, 11, 1)
			End
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'LTQ', Convert(float, @LTQ), @LTQComment, @FY)
		End
			
		If @GC <> '' 
		Begin
			If IsNumeric(@GC) = 0
			Begin
				Set @Msg2 = 'GC hours is not numeric: ' + @GC
				RAISERROR (@Msg2, 11, 1)
			End
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'GC', Convert(float, @GC), @GCComment, @FY)
		End
			
		If @QQQ <> ''
		Begin
			If IsNumeric(@QQQ) = 0
			Begin
				Set @Msg2 = 'QQQ hours is not numeric: ' + @QQQ
				RAISERROR (@Msg2, 11, 1)
			End
				INSERT INTO #T_OPS (Operation, Proposal, InstGroup, Allocation, Comment, FY)
				VALUES ('',  @ProposalID, 'QQQ', Convert(float, @QQQ), @QQQComment, @FY)
		End
		
		-----------------------------------------------------------
		-- Call UpdateInstrumentUsageAllocationsWork to perform the work
		-----------------------------------------------------------
		--
		EXEC @myError = UpdateInstrumentUsageAllocationsWork @fy, @message output, @callingUser, @infoOnly
		
		

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateInstrumentUsageAllocations] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentUsageAllocations] TO [PNL\D3M578] AS [dbo]
GO
