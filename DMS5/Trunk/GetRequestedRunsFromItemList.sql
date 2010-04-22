/****** Object:  StoredProcedure [dbo].[GetRequestedRunsFromItemList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetRequestedRunsFromItemList
/****************************************************
**
**	Desc: 
**		Populates the #REQ table (created by caller)
**		with requested runs determined by delimited
**      item list
**
**	Auth:	grk
**	Date:	03/22/2010
**	03/22/2010 grk - initial release
**    
*****************************************************/
(
	@itemList TEXT,
	@itemType VARCHAR(32) = 'Batch_ID',
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
		
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	IF ISNULL(@itemType, '') = ''
	BEGIN
		set @message = 'Item Type may not be blank'
		return 51051	
	END
	
	IF DATALENGTH(@itemList) = 0
	BEGIN
		set @message = 'Item List may not be blank'
		return 51051	
	END

	-----------------------------------------
	-- convert item list into temp table
	-----------------------------------------
	--
	CREATE TABLE #ITEMS (
		Item VARCHAR(128)
	)
	--
	INSERT INTO #ITEMS
        (Item)
	SELECT 
		Item 
	FROM 
		dbo.MakeTableFromList(@itemList)

	-----------------------------------------
	-- Validate the list items
	-----------------------------------------

	DECLARE @errMsg VARCHAR(256)
	DECLARE @item VARCHAR(128)
	SET @item = ''
	--
	IF @itemType = 'Batch_ID' 
	BEGIN 
		SELECT @Item = Item FROM #ITEMS WHERE Item NOT IN (SELECT CONVERT(VARCHAR(12), ID) AS Item FROM dbo.T_Requested_Run_Batches)
	END 
	ELSE
	IF @itemType = 'Requested_Run_ID'
	BEGIN
		SELECT @Item = Item FROM #ITEMS WHERE Item NOT IN (SELECT CONVERT(VARCHAR(12), ID) AS Item FROM dbo.T_Requested_Run)
	END
	ELSE
	IF @itemType = 'Dataset_Name'
	BEGIN
		SELECT @Item = Item FROM #ITEMS WHERE Item NOT IN (SELECT Dataset_Num FROM dbo.T_Dataset)
	END
	ELSE
	IF @itemType = 'Dataset_ID'
	BEGIN
		SELECT @Item = Item FROM #ITEMS WHERE Item NOT IN (SELECT CONVERT(VARCHAR(12), Dataset_ID) AS Item FROM dbo.T_Dataset)
	END
	ELSE
	IF @itemType = 'Experiment_Name'
	BEGIN
		SELECT @Item = Item FROM #ITEMS WHERE Item NOT IN (SELECT Experiment_Num FROM dbo.T_Experiments)
	END
	ELSE
	IF @itemType = 'Experiment_ID'
	BEGIN
		SELECT @Item = Item FROM #ITEMS WHERE Item NOT IN (SELECT CONVERT(VARCHAR(12), Exp_ID) AS Item FROM dbo.T_Experiments)
	END
	--
	If @item <> ''
	Begin
		SET @message = '"' + @item + '" is not a valid ' + replace(@itemType, '_', ' ')
		return 51005
	End
	
	-----------------------------------------
	-- populate temp request table according 
	-- to type of items in list
	-----------------------------------------
	--
	IF @itemType = 'Batch_ID'
	BEGIN 
		INSERT INTO #REQS
			( Request )
		SELECT Request 
		FROM V_Requested_Run_Unified_List
		WHERE BatchID IN (SELECT Item FROM #ITEMS)
	END 
	ELSE
	IF @itemType = 'Requested_Run_ID'
	BEGIN
		INSERT INTO #REQS
			( Request )
		SELECT Request 
		FROM V_Requested_Run_Unified_List
		WHERE Request IN (SELECT Item FROM #ITEMS)	
	END
	ELSE
	IF @itemType = 'Dataset_Name' 
	BEGIN
		INSERT INTO #REQS
			( Request )
		SELECT Request 
		FROM V_Requested_Run_Unified_List
		WHERE Dataset IN (SELECT Item FROM #ITEMS)	
	END
	ELSE
	IF @itemType = 'Dataset_ID' 
	BEGIN 
		INSERT INTO #REQS
			( Request )
		SELECT Request 
		FROM V_Requested_Run_Unified_List
		WHERE Dataset_ID IN (SELECT Item FROM #ITEMS)	
	END
	ELSE
	IF @itemType = 'Experiment_Name' 
	BEGIN 
		INSERT INTO #REQS
			( Request )
		SELECT Request 
		FROM V_Requested_Run_Unified_List
		WHERE Experiment IN (SELECT Item FROM #ITEMS)	
	END
	ELSE
	IF @itemType = 'Experiment_ID' 
	BEGIN 
		INSERT INTO #REQS
			( Request )
		SELECT Request 
		FROM V_Requested_Run_Unified_List
		WHERE Experiment_ID IN (SELECT Item FROM #ITEMS)	
	END
GO
GRANT EXECUTE ON [dbo].[GetRequestedRunsFromItemList] TO [DMS2_SP_User] AS [dbo]
GO
