/****** Object:  StoredProcedure [dbo].[UpdateDatasetDispositionsByName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDatasetDispositionsByName
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
**	Date:	10/15/08 grk -- initial release (Ticket #582)
**
*****************************************************/
(
    @datasetList varchar(6000),
    @rating varchar(64) = '',
    @comment varchar(512) = '',
    @recycleRequest varchar(32) = '', -- yes/no
    @mode varchar(12) = 'update',
    @message varchar(512) output,
   	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

 	---------------------------------------------------
	-- convert dataset name list into dataset ID list
	---------------------------------------------------
    
 	---------------------------------------------------
	-- table variable for holding datasets from list
	---------------------------------------------------
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
		return 51007
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
		return 51008
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
		return 51010
	end
	--
	if @myRowCount > 0
	begin
		set @message = 'Datasets not found: ' + @datasetIDList
		return 51011
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
		return 51009
	end

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
/**/	
 	---------------------------------------------------
	-- 
	---------------------------------------------------
	
	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateDatasetDispositionsByName] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDispositionsByName] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetDispositionsByName] TO [PNL\D3M580] AS [dbo]
GO
