/****** Object:  StoredProcedure [dbo].[AddNewDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewDataset
/****************************************************
**	Desc: 
**		Adds new dataset entry to DMS database from contents of XML.
**
**		This is for use by sample automation software
**		associated with the mass spec instrument to
**		create new datasets automatically following
**		an instrument run.
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	grk
**			05/04/2007 grk - Ticket #434
**			10/02/2007 grk - Automatically release QC datasets (http://prismtrac.pnl.gov/trac/ticket/540)
**			10/02/2007 mem - Updated to query T_DatasetRatingName for rating 5=Released
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
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	DECLARE
		@Dataset_Name		varchar(64),  -- @datasetNum
		@Experiment_Name	varchar(64),  -- @experimentNum
		@Instrument_Name	varchar(64),  -- @instrumentName
		@Separation_Type	varchar(64),  -- @secSep
		@LC_Cart_Name		varchar(128), -- @LCCartName
		@LC_Column			varchar(64),  -- @LCColumnNum
		@Wellplate_Number	varchar(64),  -- @wellplateNum
		@Well_Number		varchar(64),  -- @wellNum
		@Dataset_Type		varchar(20),  -- @msType
		@Operator_PRN		varchar(64),  -- @operPRN
		@Comment			varchar(512), -- @comment
		@Interest_Rating	varchar(32),  -- @rating
		@Request			int,          -- @requestID
		@EMSL_Usage_Type	varchar(50),  -- @eusUsageType
		@EMSL_Proposal_ID	varchar(10),  -- @eusProposalID
		@EMSL_Users_List	varchar(1024), -- @eusUsersList
		@Run_Start		    varchar(64),
		@Run_Finish		    varchar(64)

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
	DECLARE @hDoc int
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

 	---------------------------------------------------
	-- check for QC datasets
 	---------------------------------------------------

	if dbo.DatasetPreference(@Dataset_Name) <> 0
	begin
		-- Auto set interest rating to 5
		-- Initially set @Interest_Rating to the text 'released' but then query
		--  T_DatasetRatingName for rating 5 in case the rating name has changed
		
		set @Interest_Rating = 'Released'

		SELECT @Interest_Rating = DRN_name
		FROM T_DatasetRatingName
		WHERE (DRN_state_ID = 5)
	end

 	---------------------------------------------------
	-- establish default parameters
 	---------------------------------------------------

	declare @internalStandards varchar(64)
	set @internalStandards  = 'none'

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
	-- Find request associated with dataset (if not given)
	---------------------------------------------------
	
	if @Request = 0
	begin
		---------------------------------------------------
		-- get dataset ID from dataset name
		--
		declare @dsid int
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
		-- get request ID using dataset ID
		--
		declare @tmp int
		set @tmp = 0
		--
		SELECT @tmp = ID
		FROM T_Requested_Run_History
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
		if @tmp = 0
		begin
			set @message = 'Could not find request'
			RAISERROR (@message, 10, 1)
			return 51037
		end
		set @Request = @tmp
	end

	---------------------------------------------------
	-- Update the associated request with run start/finish values
	---------------------------------------------------

	UPDATE T_Requested_Run_History
	SET
		RDS_Run_Start = @Run_Start, 
		RDS_Run_Finish = @Run_Finish
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

 	---------------------------------------------------
	-- 
 	---------------------------------------------------
Done:
	return @myError
GO
GRANT EXECUTE ON [dbo].[AddNewDataset] TO [DMS_DS_Entry]
GO
