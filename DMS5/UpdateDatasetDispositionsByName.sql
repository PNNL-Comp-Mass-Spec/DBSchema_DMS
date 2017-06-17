/****** Object:  StoredProcedure [dbo].[UpdateDatasetDispositionsByName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateDatasetDispositionsByName
/****************************************************
**
**	Desc:
**      Updates datasets in list according to disposition parameters
**      Accepts list of dataset names
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	10/15/2008 grk -- initial release (Ticket #582)
**			08/19/2010 grk - try-catch for error handling
**			09/02/2011 mem - Now calling PostUsageLogEntry
**			02/20/2013 mem - Expanded @message to varchar(1024)
**			02/21/2013 mem - Now requiring @recycleRequest to be yes or no
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**
*****************************************************/
(
    @datasetList varchar(6000),
    @rating varchar(64) = '',
    @comment varchar(512) = '',
    @recycleRequest varchar(32) = '', -- yes/no
    @mode varchar(12) = 'update',
    @message varchar(1024) output,
   	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	Declare @datasetCount int = 0

	BEGIN TRY 

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateDatasetDispositionsByName', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

 	---------------------------------------------------
	-- Validate input parameters
 	---------------------------------------------------
 	
 	Set @rating = IsNull(@rating, '')
	Set @recycleRequest = IsNull(@recycleRequest, '')
	Set @comment = IsNull(@comment, '')
	
	If Not @recycleRequest IN ('yes', 'no')
	Begin
		set @message = 'RecycleRequest must be Yes or No (currently "' + @recycleRequest + '")'
		RAISERROR (@message, 11, 11)
	End
	
 	---------------------------------------------------
	-- convert dataset name list into dataset ID list
	---------------------------------------------------
	-- table variable for holding datasets from list
	--
  	declare @tbl table (
		DatasetID varchar(12),
		DatasetName varchar(128)
	)
   
 	---------------------------------------------------
	-- add datasets from input list to table
	---------------------------------------------------
	--
	INSERT INTO @tbl
	(DatasetName)
	SELECT Item
	FROM MakeTableFromList(@datasetList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary dataset table'
		RAISERROR (@message, 11, 7)
	end

 	---------------------------------------------------
	-- look up dataset IDs for datasets
	---------------------------------------------------
	--
	update @tbl
	set DatasetID = convert(varchar(12), D.Dataset_ID)
	from @tbl T inner join
	T_Dataset D on D.Dataset_Num = T.DatasetName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error finding dataset IDs'
		RAISERROR (@message, 11, 8)
	end

 	---------------------------------------------------
	-- any datasets not found?
	---------------------------------------------------
    declare @datasetIDList varchar(6000)
    set @datasetIDList = ''
    
    select @datasetIDList =  @datasetIDList + case when @datasetIDList = '' then '' else ', ' end + DatasetName
    from @tbl
    where DatasetID is Null
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for missing datasets'
		RAISERROR (@message, 11, 10)
	end
	--
	if @myRowCount > 0
	begin
		set @message = 'Datasets not found: ' + @datasetIDList
		RAISERROR (@message, 11, 11)
	end

 	---------------------------------------------------
	-- make list of dataset IDs
	---------------------------------------------------

    set @datasetIDList = ''
    
    select @datasetIDList =  @datasetIDList + case when @datasetIDList = '' then '' else ', ' end + DatasetID
    from @tbl
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error making dataset ID list'
		RAISERROR (@message, 11, 12)
	end

	Set @datasetCount = @myRowCount

 	---------------------------------------------------
	-- call sproc to update dataset disposition
	---------------------------------------------------

	exec @myError = UpdateDatasetDispositions
						@datasetIDList,
						@rating,
						@comment,
						@recycleRequest,
						@mode,
						@message output,
						@callingUser
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'UpdateDatasetDispositionsByName'
	END CATCH

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = Convert(varchar(12), @datasetCount) + ' datasets updated'
	Exec PostUsageLogEntry 'UpdateDatasetDispositionsByName', @UsageMessage

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDispositionsByName] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDispositionsByName] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDispositionsByName] TO [Limited_Table_Write] AS [dbo]
GO
