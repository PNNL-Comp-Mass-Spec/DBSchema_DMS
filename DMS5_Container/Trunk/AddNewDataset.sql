/****** Object:  StoredProcedure [dbo].[AddNewDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddNewDataset
/****************************************************
**
**	Desc: 
**		Adds new dataset entry to DMS database from contents of XML.
**
**		This is for use by sample automation software
**		associated with the mass spec instrument to
**		create new datasets automatically following
**		an instrument run.
**
**		This procedure is called by the DataImportManager (DIM)
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	grk
**			05/04/2007 grk - Ticket #434
**			10/02/2007 grk - Automatically release QC datasets (http://prismtrac.pnl.gov/trac/ticket/540)
**			10/02/2007 mem - Updated to query T_DatasetRatingName for rating 5=Released
**			10/16/2007 mem - Added support for the 'DS Creator (PRN)' field
**			01/02/2008 mem - Now setting the rating to 'Released' for datasets that start with "Blank" (Ticket #593)
**			02/13/2008 mem - Increased size of @Dataset_Name to varchar(128) (Ticket #602)
**			02/26/2010 grk - merged T_Requested_Run_History with T_Requested_Run
**			09/09/2010 mem - Now always looking up the request number associated with the new dataset
**			03/04/2011 mem - Now validating that @Run_Finish is not a future date
**			03/07/2011 mem - Now auto-defining experiment name if empty for QC_Shew and Blank datasets
**						   - Now auto-defining EMSL usage type to Maintenance for QC_Shew and Blank datasets
**			05/12/2011 mem - Now excluding Blank%-bad datasets when auto-setting rating to 'Released'
**    
*****************************************************/
(
	@xmlDoc varchar(4000),
	@mode varchar(24) = 'add', --  'add', 'parse_only', 'update', 'bad', 'check_add', 'check_update'
    @message varchar(512) output
)
AS
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	DECLARE @hDoc int
	declare @dsid int

	declare @tmp int

	declare @internalStandards varchar(64)
	declare @AddUpdateTimeStamp datetime
	
	declare @RunStartDate datetime
	declare @RunFinishDate datetime
	
	set @message = ''

	DECLARE
		@Dataset_Name		varchar(128),  -- @datasetNum
		@Experiment_Name	varchar(64),  -- @experimentNum
		@Instrument_Name	varchar(64),  -- @instrumentName
		@Separation_Type	varchar(64),  -- @secSep
		@LC_Cart_Name		varchar(128), -- @LCCartName
		@LC_Column			varchar(64),  -- @LCColumnNum
		@Wellplate_Number	varchar(64),  -- @wellplateNum
		@Well_Number		varchar(64),  -- @wellNum
		@Dataset_Type		varchar(64),  -- @msType
		@Operator_PRN		varchar(64),  -- @operPRN
		@Comment			varchar(512), -- @comment
		@Interest_Rating	varchar(32),  -- @rating
		@Request			int,          -- @requestID; this might get updated by AddUpdateDataset
		@EMSL_Usage_Type	varchar(50),  -- @eusUsageType
		@EMSL_Proposal_ID	varchar(10),  -- @eusProposalID
		@EMSL_Users_List	varchar(1024), -- @eusUsersList
		@Run_Start		    varchar(64),
		@Run_Finish		    varchar(64),
		@DatasetCreatorPRN	varchar(128)	-- PRN of the person that created the dataset; typically only present in 
											-- trigger files created due to a dataset manually being created by a user

	---------------------------------------------------
	--  Create temporary table to hold list of parameters
	---------------------------------------------------
 
 	CREATE TABLE #TPAR (
		paramName varchar(128),
		paramValue varchar(512)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary parameter table'
		goto DONE
	end
	
	---------------------------------------------------
	-- Parse the XML input
	---------------------------------------------------
	EXEC sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc

 	---------------------------------------------------
	-- Populate parameter table from XML parameter description  
	---------------------------------------------------

	INSERT INTO #TPAR (paramName, paramValue)
	SELECT * FROM OPENXML(@hDoc, N'//Parameter')  with ([Name] varchar(128), [Value] varchar(512))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary parameter table'
		goto DONE
	end
    
 	---------------------------------------------------
	-- Remove the internal representation of the XML document.
 	---------------------------------------------------
 	
	EXEC sp_xml_removedocument @hDoc

	---------------------------------------------------
	-- Trap 'parse_only' mode here
	---------------------------------------------------
	if @mode = 'parse_only'
	begin
		--
		SELECT CONVERT(char(24), paramName), paramValue FROM #TPAR
		goto DONE
	end

 	---------------------------------------------------
	-- Get agruments from parsed parameters
 	---------------------------------------------------

	SELECT	@Dataset_Name		 = paramValue FROM #TPAR WHERE paramName = 'Dataset Name' 
	SELECT	@Experiment_Name	 = paramValue FROM #TPAR WHERE paramName = 'Experiment Name' 
	SELECT	@Instrument_Name	 = paramValue FROM #TPAR WHERE paramName = 'Instrument Name' 
	SELECT	@Separation_Type	 = paramValue FROM #TPAR WHERE paramName = 'Separation Type' 
	SELECT	@LC_Cart_Name		 = paramValue FROM #TPAR WHERE paramName = 'LC Cart Name' 
	SELECT	@LC_Column			 = paramValue FROM #TPAR WHERE paramName = 'LC Column' 
	SELECT	@Wellplate_Number	 = paramValue FROM #TPAR WHERE paramName = 'Wellplate Number' 
	SELECT	@Well_Number		 = paramValue FROM #TPAR WHERE paramName = 'Well Number' 
	SELECT	@Dataset_Type		 = paramValue FROM #TPAR WHERE paramName = 'Dataset Type' 
	SELECT	@Operator_PRN		 = paramValue FROM #TPAR WHERE paramName = 'Operator (PRN)' 
	SELECT	@Comment			 = paramValue FROM #TPAR WHERE paramName = 'Comment' 
	SELECT	@Interest_Rating	 = paramValue FROM #TPAR WHERE paramName = 'Interest Rating' 
	SELECT	@Request			 = paramValue FROM #TPAR WHERE paramName = 'Request' 
	SELECT	@EMSL_Usage_Type	 = paramValue FROM #TPAR WHERE paramName = 'EMSL Usage Type' 
	SELECT	@EMSL_Proposal_ID	 = paramValue FROM #TPAR WHERE paramName = 'EMSL Proposal ID' 
	SELECT	@EMSL_Users_List	 = paramValue FROM #TPAR WHERE paramName = 'EMSL Users List' 
	SELECT	@Run_Start		   	 = paramValue FROM #TPAR WHERE paramName = 'Run Start' 
	SELECT	@Run_Finish		   	 = paramValue FROM #TPAR WHERE paramName = 'Run Finish' 
	SELECT  @DatasetCreatorPRN   = paramValue FROM #TPAR WHERE paramName = 'DS Creator (PRN)'

	---------------------------------------------------
	-- Assure that none of the values is Null
	---------------------------------------------------
	
	Set @Dataset_Name		 = IsNull(@Dataset_Name, '')
	Set @Experiment_Name	 = IsNull(@Experiment_Name, '')
	Set @Instrument_Name	 = IsNull(@Instrument_Name, '')
	Set @Separation_Type	 = IsNull(@Separation_Type, '')
	Set @LC_Cart_Name		 = IsNull(@LC_Cart_Name, '')
	Set @LC_Column			 = IsNull(@LC_Column, '')	
	Set @Wellplate_Number	 = IsNull(@Wellplate_Number, '')
	Set @Well_Number		 = IsNull(@Well_Number, '')
	Set @Dataset_Type		 = IsNull(@Dataset_Type, '')	
	Set @Operator_PRN		 = IsNull(@Operator_PRN, '')
	Set @Comment			 = IsNull(@Comment, '')
	Set @Interest_Rating	 = IsNull(@Interest_Rating, '')
	Set @Request			 = IsNull(@Request, 0)		
	Set @EMSL_Usage_Type	 = IsNull(@EMSL_Usage_Type, '')
	Set @EMSL_Proposal_ID	 = IsNull(@EMSL_Proposal_ID, '')
	Set @EMSL_Users_List	 = IsNull(@EMSL_Users_List, '')
	Set @Run_Start		   	 = IsNull(@Run_Start, '')
	Set @Run_Finish		   	 = IsNull(@Run_Finish, '')
	Set @DatasetCreatorPRN   = IsNull(@DatasetCreatorPRN, '')
	
 	---------------------------------------------------
	-- check for QC or Blank datasets
 	---------------------------------------------------

	if dbo.DatasetPreference(@Dataset_Name) <> 0 OR (@Dataset_Name LIKE 'Blank%' AND Not @Dataset_Name LIKE '%-bad')
	begin
		-- Auto set interest rating to 5
		-- Initially set @Interest_Rating to the text 'Released' but then query
		--  T_DatasetRatingName for rating 5 in case the rating name has changed
		
		set @Interest_Rating = 'Released'

		SELECT @Interest_Rating = DRN_name
		FROM T_DatasetRatingName
		WHERE (DRN_state_ID = 5)
	end

 	---------------------------------------------------
	-- Possibly auto-define the experiment
 	---------------------------------------------------
 	--
	if @Experiment_Name = ''
	Begin
		If @Dataset_Name Like 'Blank%'
			Set @Experiment_Name = 'Blank'
		Else
		If @Dataset_Name Like 'QC_Shew_1[0-9]_[0-9][0-9]%'
			Set @Experiment_Name = Substring(@Dataset_Name, 1, 13)
		
	End
	
 	---------------------------------------------------
	-- Possibly auto-define the @EMSL_Usage_Type
 	---------------------------------------------------
 	--
	if @EMSL_Usage_Type = ''
	Begin
		If @Dataset_Name Like 'Blank%' OR @Dataset_Name Like 'QC_Shew%'
			Set @EMSL_Usage_Type = 'MAINTENANCE'
	End

 	---------------------------------------------------
	-- establish default parameters
 	---------------------------------------------------

	set @internalStandards  = 'none'
	set @AddUpdateTimeStamp = GetDate()
	
	---------------------------------------------------
	-- Create new dataset
	---------------------------------------------------
	exec @myError = AddUpdateDataset
						@Dataset_Name,
						@Experiment_Name,
						@Operator_PRN,
						@Instrument_Name,
						@Dataset_Type,
						@LC_Column,
						@Wellplate_Number,
						@Well_Number,
						@Separation_Type,
						@internalStandards,
						@Comment,
						@Interest_Rating,
						@LC_Cart_Name,
						@EMSL_Proposal_ID,
						@EMSL_Usage_Type,
						@EMSL_Users_List,
						@Request,
						@mode,
						@message output
	if @myError <> 0
	begin
		RAISERROR (@message, 10, 1)
		return 51032
	end

	---------------------------------------------------
	-- Trap 'check' modes here
	---------------------------------------------------
	if @mode = 'check_add' OR @mode = 'check_update'
		goto DONE


	---------------------------------------------------
	-- It's possible that @Request got updated by AddUpdateDataset
	-- Lookup the current value
	---------------------------------------------------
	
	-- First use Dataset Name to lookup the Dataset ID
	--		
	set @dsid = 0
	--
	SELECT @dsid = Dataset_ID
	FROM T_Dataset
	WHERE (Dataset_Num = @Dataset_Name)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to resolve dataset ID'
		RAISERROR (@message, 10, 1)
		return 51034
	end
	if @dsid = 0
	begin
		set @message = 'Could not resolve dataset ID'
		RAISERROR (@message, 10, 1)
		return 51035
	end
	
	---------------------------------------------------
	-- Find request associated with dataset
	---------------------------------------------------
	
	set @tmp = 0
	--
	SELECT @tmp = ID
	FROM T_Requested_Run
	WHERE (DatasetID = @dsid)		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to resolve request ID'
		RAISERROR (@message, 10, 1)
		return 51036
	end
	
	if @tmp <> 0
		set @Request = @tmp
	
	
	If Len(@DatasetCreatorPRN) > 0
	Begin -- <a>
		---------------------------------------------------
		-- Update T_Event_Log to reflect @DatasetCreatorPRN creating this dataset
		---------------------------------------------------
		
		UPDATE T_Event_Log
		SET Entered_By = @DatasetCreatorPRN + '; via ' + IsNull(Entered_By, '')
		FROM T_Event_Log
		WHERE Target_ID = @dsid AND
				Target_State = 1 AND 
				Target_Type = 4 AND 
				Entered Between @AddUpdateTimeStamp AND DateAdd(minute, 1, @AddUpdateTimeStamp)
			
	End -- </a>
		

	---------------------------------------------------
	-- Update the associated request with run start/finish values
	---------------------------------------------------

	If @Request <> 0
	Begin
	
		If @Run_Start <> ''
			Set @RunStartDate = Convert(datetime, @Run_Start)
		Else
			Set @RunStartDate = Null
			
		If @Run_Finish <> ''
			Set @RunFinishDate = Convert(datetime, @Run_Finish)
		Else
			Set @RunFinishDate = Null
			
		If Not @RunStartDate Is Null and Not @RunFinishDate Is Null
		Begin
			-- Check whether the @RunFinishDate value is in the future
			-- If it is, update it to match @RunStartDate
			If DateDiff(day, GetDate(), @RunFinishDate) > 1
				Set @RunFinishDate = @RunStartDate			
		End
		
		UPDATE T_Requested_Run
		SET
			RDS_Run_Start = @RunStartDate, 
			RDS_Run_Finish = @RunFinishDate
		WHERE (ID = @Request)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to update run times'
			RAISERROR (@message, 10, 1)
			return 51033
		end
	End

 	---------------------------------------------------
	-- Done
 	---------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[AddNewDataset] TO [DMS_DS_Entry] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewDataset] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewDataset] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewDataset] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddNewDataset] TO [svc-dms] AS [dbo]
GO
