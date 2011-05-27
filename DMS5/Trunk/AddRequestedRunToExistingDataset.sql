/****** Object:  StoredProcedure [dbo].[AddRequestedRunToExistingDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddRequestedRunToExistingDataset
/****************************************************
**
**	Desc: 
**		Creates a requested run and associates it with
**		the given dataset if there is not currently one
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	grk
**			05/23/2011 grk - initial release
**    
*****************************************************/
(
	@datasetID INT = 0,        -- can supply ID for dataset
	@datasetNum varchar(128),  -- or name for dataset (but not both)
	@templateRequestID INT,    -- existing request to use for looking up some parameters for new one
	@mode varchar(12) = 'add', -- compatibility with web entry page and possible future use
	@message varchar(512) output,
   	@callingUser varchar(128) = ''
)
AS
	SET NOCOUNT ON

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
			
	BEGIN TRY 

	---------------------------------------------------
	-- validate dataset identification 
	--(either name or ID, but not both)
	---------------------------------------------------

	DECLARE
		@dID INT = 0,
		@dName VARCHAR(128) = ''
	
	SET @datasetID = ISNULL(@datasetID, 0)
	SET @datasetNum = ISNULL(@datasetNum, '')
	
	if @datasetID <> 0 AND @datasetNum <> ''
	RAISERROR ('Cannot specify both datasetID "%d" and datasetNum "%s"', 11, 3, @datasetID, @datasetNum)
	
	---------------------------------------------------
	-- does dataset exist?
	---------------------------------------------------
	
	SELECT 
		@dID = Dataset_ID, 
		@dName = Dataset_Num
	FROM   dbo.T_Dataset
	WHERE  
	Dataset_Num = @datasetNum OR Dataset_ID = @datasetID

	if @dID = 0
	RAISERROR ('Could not find datasetID "%d" or dataset "%s"', 11, 4, @datasetID, @datasetNum)

	---------------------------------------------------
	-- does the dataset have an associated request?
	---------------------------------------------------
	DECLARE 
		@rID INT = 0
		
	SELECT @rID = RR.ID
	FROM   T_Requested_Run AS RR
	WHERE  RR.DatasetID = @dID

	if @rID <> 0
	RAISERROR ('Dataset "%d" has existing requested run "%d"', 11, 5, @dID, @rID)

	---------------------------------------------------
	-- parameters for creating requested run
	---------------------------------------------------
	DECLARE 
	@reqName varchar(128) = 'AutoReq_' + @dName,
	@experimentNum varchar(64),
	@instrumentName varchar(64),
	@msType varchar(20),
	@comment varchar(1024) = 'na',
	@workPackage varchar(50)  = 'none',
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@request int = 0,
	@secSep varchar(64) = 'LC-ISCO-Standard',
	@msg VARCHAR(512) = ''

	---------------------------------------------------
	-- fill in some requested run parameters from dataset
	---------------------------------------------------

	SELECT
		@experimentNum = TEXP.Experiment_Num ,
		@instrumentName = TIN.IN_name ,
		@msType = TDTN.DST_name ,
		@secSep = TSEP.SS_name
	FROM
		T_Dataset AS TD
		INNER JOIN T_Instrument_Name AS TIN ON TD.DS_instrument_name_ID = TIN.Instrument_ID
		INNER JOIN T_DatasetTypeName AS TDTN ON TD.DS_type_ID = TDTN.DST_Type_ID
		INNER JOIN T_Experiments AS TEXP ON TD.Exp_ID = TEXP.Exp_ID
		INNER JOIN T_Secondary_Sep AS TSEP ON TD.DS_sec_sep = TSEP.SS_name
	WHERE 
		TD.Dataset_ID = @dID

	---------------------------------------------------
	-- fill in some parameters from existing requested run 
	-- (if an ID was provided in @templateRequestID)
	---------------------------------------------------
	
	IF ISNULL(@templateRequestID, 0) <> 0
	BEGIN 
		SELECT  
			@workPackage = RDS_WorkPackage ,
			@eusProposalID = RDS_EUS_Proposal_ID ,
			@eusUsageType = EUT.Name ,
			@eusUsersList = dbo.GetRequestedRunEUSUsersList(RR.ID, 'I')
		FROM
			T_Requested_Run AS RR
			INNER JOIN dbo.T_EUS_UsageType AS EUT ON RR.RDS_EUS_UsageType = EUT.ID
		WHERE
			RR.ID = @templateRequestID			
	END 

	---------------------------------------------------
	-- set up EUS parameters
	---------------------------------------------------
	
	IF ISNULL(@templateRequestID, 0) = 0
		RAISERROR ('For now, a template request is mandatory', 11, 10)

	---------------------------------------------------
	-- create requested run and attach it to dataset
	---------------------------------------------------	
	
	EXEC @myError = dbo.AddUpdateRequestedRun 
							@reqName = @reqName,
							@experimentNum = @experimentNum,
							@operPRN = @callingUser,
							@instrumentName = @instrumentName,
							@workPackage = @workPackage,
							@msType = @msType,
							@instrumentSettings = 'na',
							@wellplateNum = 'na',
							@wellNum = 'na',
							@internalStandard = 'na',
							@comment = 'Automatically created by Dataset entry',
							@eusProposalID = @eusProposalID,
							@eusUsageType = @eusUsageType,
							@eusUsersList = @eusUsersList,
							@mode = 'add-auto',
							@request = @request output,
							@message = @msg output,
							@secSep = @secSep,
							@MRMAttachment = '',
							@status = 'Completed',
							@SkipTransactionRollback = 1,
							@AutoPopulateUserListIfBlank = 1		-- Auto populate @eusUsersList if blank since this is an Auto-Request

	if @myError <> 0
		RAISERROR (@msg, 11, 6)
		
	IF @request = 0
		RAISERROR('Created request with ID = 0', 11, 7)

	---------------------------------------------------
	-- consume the requested run 
	---------------------------------------------------
			
	exec @myError = ConsumeScheduledRun @dID, @request, @msg output
	if @myError <> 0
		RAISERROR (@msg, 11, 8)

	---------------------------------------------------
	-- Errors end up here
	---------------------------------------------------

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[AddRequestedRunToExistingDataset] TO [DMS2_SP_User] AS [dbo]
GO
