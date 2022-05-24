/****** Object:  StoredProcedure [dbo].[AddMissingRequestedRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddMissingRequestedRun]
/****************************************************
**
**	Desc:	Creates a requested run for the given dataset,
**			provided it doesn't already have a requested run
**
**			The requested run will be named 'AutoReq_DatasetName'
**
**
**			Note that this procedure is similar to AddRequestedRunToExistingDataset, 
**			though that procedure has parameter @templateRequestID which defines
**			an existing requested run ID from which to lookup EUS information
**
**			In contrast, this procedure is intended to be run via automation
**			to add requested runs to existing datasets that don't yet have one
**
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	10/20/1010 mem - Initial version
**			05/08/2013 mem - Now setting @wellplateNum and @wellNum to Null when calling AddUpdateRequestedRun
**			01/29/2016 mem - Now calling GetWPforEUSProposal to get the best work package for the given EUS Proposal
**			06/13/2017 mem - Rename @operPRN to @requestorPRN when calling AddUpdateRequestedRun
**          05/23/2022 mem - Rename @requestorPRN to @requesterPRN when calling AddUpdateRequestedRun
**
*****************************************************/
(
	@Dataset varchar(256),
	@eusProposalID varchar(64) = '',
	@eusUsageType varchar(64) = 'Cap_Dev',
	@eusUsersList varchar(64) = '',
	@InfoOnly tinyint = 1,
	@message varchar(512) = '' output
)
As
	Set nocount on

	declare @myError int
	declare @myRowCount int
	Set @myError = 0
	Set @myRowCount = 0

	Declare @experimentNum varchar(256),
			@operPRN varchar(64),
			@instrumentName varchar(128),
			@secSep varchar(128),
			@msType varchar(64),
			@DatasetID int,
			@RequestID int
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @Dataset = IsNull(@Dataset, '')
	Set @InfoOnly = IsNull(@InfoOnly, 1)
	Set @message = ''
	
	---------------------------------------------------
	-- Lookup the dataset details
	---------------------------------------------------

	SELECT @experimentNum = V.Experiment,
	       @operPRN = D.DS_Oper_PRN,
	       @instrumentName = v.Instrument,
	       @msType = v.Type,
	       @secSep = v.[Separation Type],
	       @DatasetID = D.Dataset_ID
	FROM V_Dataset_Detail_Report_Ex V
	     INNER JOIN T_Dataset D
	       ON V.Dataset = D.Dataset_Num
	WHERE V.Dataset = @Dataset
	--
	SELECT @myError = @@Error, @myRowCount = @@RowCount

	IF @myRowCount = 0
	BEGIN
		Set @message = 'Error, Dataset not found: ' + @Dataset
		Set @myError = 50000
		GOTO Done
	End

	---------------------------------------------------
	-- Make sure the dataset doesn't already have a requested run
	---------------------------------------------------

	Set @RequestID = 0
	SELECT @RequestID = T_Requested_Run.ID
	FROM T_Requested_Run
	     INNER JOIN T_Dataset
	       ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
	WHERE (T_Dataset.Dataset_Num = @Dataset)
	--
	SELECT @myError = @@Error, @myRowCount = @@RowCount

	If @myRowCount > 0
	Begin
		Set @message = 'Error, Dataset is already associated with Request ' + Convert(varchar(12), @RequestID)
		Set @myError = 50001
		GOTO Done
	End


	If @infoOnly <> 0
	Begin
		SELECT @DatasetID AS DatasetID,
		       @Dataset AS Dataset,
		       @experimentNum AS Experiment,
		       @operPRN AS Operator,
		       @instrumentName AS Instrument,
		       @msType AS DS_Type,
		       @message AS Message
	End
	Else
	Begin
		-- Create the request

		declare @reqName varchar(128)
		Set @reqName = 'AutoReq_' + @Dataset

		Declare @workPackage varchar(50) = 'none'			
		EXEC GetWPforEUSProposal @eusProposalID, @workPackage OUTPUT

		DECLARE @result int

		EXEC @result = dbo.AddUpdateRequestedRun 
								@reqName = @reqName,
								@experimentNum = @experimentNum,
								@requesterPRN = @operPRN,
								@instrumentName = @instrumentName,
								@workPackage = @workPackage,
								@msType = @msType,
								@instrumentSettings = 'na',
								@wellplateNum = NULL,
								@wellNum = NULL,
								@internalStandard = 'na',
								@comment = 'Automatically created by Dataset entry',
								@eusProposalID = @eusProposalID,
								@eusUsageType = @eusUsageType,
								@eusUsersList = @eusUsersList,
								@mode = 'add-auto',
								@request = @RequestID output,
								@message = @message output,
								@secSep = @secSep,
								@MRMAttachment = '',
								@status = 'Completed',
								@SkipTransactionRollback = 1,
								@AutoPopulateUserListIfBlank = 1		-- Auto populate @eusUsersList if blank since this is an Auto-Request

		If IsNull(@result, 0) > 0 Or IsNull(@RequestID, 0) = 0
		Begin
			If IsNull(@message, '') = ''
				Set @message = 'Error creating requested run'

			Set @myError = @result
			if @myError = 0
				Set @myError = 50003				
			
			GOTO Done
		End
		Else
		Begin
			UPDATE T_Requested_Run
			SET DatasetID = @DatasetID
			WHERE (ID = @RequestID)
			--
			SELECT @myError = @@Error, @myRowCount = @@RowCount
			
			If IsNull(@message, '') = ''
				Set @message = 'Success'
	
			SELECT @Dataset AS Dataset,
			       @RequestID AS RequestID,
			       @result AS Result,
			       @message AS Message

		End
	End


Done:
	If @myError <> 0
		print @message
		
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddMissingRequestedRun] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddMissingRequestedRun] TO [Limited_Table_Write] AS [dbo]
GO
