/****** Object:  StoredProcedure [dbo].[UpdateDatasetRestoreRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure UpdateDatasetRestoreRequest
/****************************************************
**
**	Desc: 
**	Sets state of datasets in list to "Restore Required" 
**	Verifies that all datasets are in correct state first
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/27/2006
**    
*****************************************************/
	@datasetIDList varchar(2048),
	@message varchar(512) output
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	---------------------------------------------------
	-- verify that all datasets in list are in correct
	-- state
	---------------------------------------------------
	declare @cnt int
	set @cnt = -1
	--
	SELECT @cnt = count(*)
	FROM 
		T_Dataset_Archive INNER JOIN
		T_Dataset ON T_Dataset_Archive.AS_Dataset_ID = T_Dataset.Dataset_ID
	WHERE
		NOT (T_Dataset_Archive.AS_state_ID = 4 AND T_Dataset.DS_state_ID = 3) AND
		T_Dataset.Dataset_ID IN 
		(
			SELECT * FROM dbo.MakeTableFromList(@datasetIDList)
		)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to verify dataset state', 10, 1)
		return 51310
	end
	--
	if @cnt <> 0
	begin
		RAISERROR ('Some datasets were not in proper state', 10, 1)
		return 51310
	end

	---------------------------------------------------
	-- Update state of datasets in list
	---------------------------------------------------

	UPDATE T_Dataset
	SET DS_state_ID = 10
	WHERE Dataset_ID IN 
		(
			SELECT * FROM dbo.MakeTableFromList(@datasetIDList)
		)
	--	
	SELECT @myError = @@error, @myRowCount = @@rowcount				
	--
	if @myError <> 0
	begin
		RAISERROR ('Error trying to update dataset state', 10, 1)
		return 51310
	end
/**/	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateDatasetRestoreRequest] TO [DMS_Archive_Restore] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetRestoreRequest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetRestoreRequest] TO [PNL\D3M580] AS [dbo]
GO
