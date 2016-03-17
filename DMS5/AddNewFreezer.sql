/****** Object:  StoredProcedure [dbo].[AddNewFreezer] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AddNewFreezer
/****************************************************
**
**	Desc: Adds a new Freezer to T_Material_Locations
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	04/22/2015 mem - Initial version
**    
*****************************************************/
(
	@sourceFreezer varchar(24) = '-80 BSF2240B',
	@newFreezer varchar(24) = '-80 BSF1215A',
	@NewTagBase varchar(6) = '1215A',
	@infoOnly tinyint = 1,
	@message varchar(512) = '' output
)
As
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	Set @sourceFreezer = IsNull(@sourceFreezer, '')
	Set @newFreezer = IsNull(@newFreezer, '')
	Set @NewTagBase = IsNull(@NewTagBase, '')
	set @infoOnly = IsNull(@infoOnly, 1)
	set @message = ''
	
	If @NewTagBase = ''
	Begin
		set @message = '@NewTagBase is empty'
		RAISERROR (@message, 10, 1)
		return 51000
	End
	
	If Len(@NewTagBase) < 4
	Begin
		set @message = '@NewTagBase should be at least 4 characters long, e.g. 1213A'
		RAISERROR (@message, 10, 1)
		return 51001
	End
	
	---------------------------------------------------
	-- Validate the freezer names
	---------------------------------------------------
	--

	If @sourceFreezer = ''
	Begin
		set @message = 'Source freezer name is empty'
		RAISERROR (@message, 10, 1)
		return 51002
	End
	
	If @newFreezer = ''
	Begin
		set @message = 'New freezer name is empty'
		RAISERROR (@message, 10, 1)
		return 51003
	End
	
	Declare @ComparisonOperator varchar(24) = @NewTagBase + '.' + '%'
	
	If Exists (SELECT * FROM T_Material_Locations WHERE Tag Like @ComparisonOperator)
	Begin
		set @message = 'Cannot add ''' + @newFreezer + ''' because existing rows have tags that start with ' + @NewTagBase + '.'
		RAISERROR (@message, 10, 1)
		return 51004
	End
	
	Set @ComparisonOperator = '%' + @NewTagBase + '%'
	If Not @newFreezer Like @ComparisonOperator
	Begin
		set @message = 'Cannot add the new freezer because its name does not contain @NewTagBase: ' + @newFreezer + ' vs. ' + @NewTagBase
		RAISERROR (@message, 10, 1)
		return 51004
	End
	
	
	If Not Exists (SELECT * FROM T_Material_Locations WHERE (Freezer = @sourceFreezer))
	Begin
		set @message = 'Source freezer not found: ' + @sourceFreezer
		RAISERROR (@message, 10, 1)
		return 51004
	End

	If Exists (SELECT * FROM T_Material_Locations WHERE (Freezer = @newFreezer))
	Begin
		set @message = 'New freezer already exists: ' + @newFreezer
		RAISERROR (@message, 10, 1)
		return 51005
	End

	---------------------------------------------------
	-- Determine the tag base
	-- For example the base for 2240B.4.1.1.2 is 2240B
	---------------------------------------------------
	--
	Declare @TagBase varchar(24) = ''
	
	SELECT Top 1 @TagBase = SUBSTRING(Tag, 1, CHARINDEX('.', Tag) - 1)
	FROM ( SELECT Tag
	       FROM T_Material_Locations
	       WHERE (Tag LIKE '%.%') AND
	             (Freezer = @sourceFreezer) 
	      ) SourceQ
	ORDER BY Tag	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or IsNull(@TagBase, '') = ''
	begin
		set @message = 'Error determining the tag base for freezer ' + @sourceFreezer
		RAISERROR (@message, 10, 1)
		return 51005
	end

	---------------------------------------------------
	-- Cache the new rows in a temporary table
	---------------------------------------------------
	--
	CREATE TABLE #Tmp_T_Material_Locations (
	    ID              int IDENTITY ( 1000, 1 ) NOT NULL,
	    Tag             varchar(24) NULL,
	    Freezer         varchar(50) NOT NULL,
	    Shelf           varchar(50) NOT NULL,
	    Rack            varchar(50) NOT NULL,
	    Row             varchar(50) NOT NULL,
	    Col             varchar(50) NOT NULL,
	    Status          varchar(32) NOT NULL,
	    Barcode         varchar(50) NULL,
	    Comment         varchar(512) NULL,
	    Container_Limit int NOT NULL
	)

	INSERT INTO #Tmp_T_Material_Locations( Tag,
	                                       Freezer,
	             Shelf,
	 Rack,
	         Row,
	                                       Col,
	                                       Status,
	                                       Barcode,
	                                       [Comment],
	                                       Container_Limit )
	SELECT Replace(Tag, @TagBase, @NewTagBase) AS NewTag,
	       @newFreezer AS freezer,
	       Shelf,
	       Rack,
	       Row,
	       Col,
	       Status,
	       Barcode,
	       [Comment],
	       Container_Limit
	FROM T_Material_Locations
	WHERE (Freezer = @sourceFreezer) AND
	      (NOT (ID IN ( SELECT ID
	                    FROM T_Material_Locations
	                    WHERE (Freezer = @sourceFreezer) AND
	                          (Status = 'inactive') AND
	                          (Col = 'na') )))
	ORDER BY Shelf, Rack, Row, Col
	
	---------------------------------------------------
	-- Preview or store the rows
	---------------------------------------------------
	--
	If @infoOnly <> 0
	Begin
		SELECT *
		FROM #Tmp_T_Material_Locations
		ORDER BY Shelf, Rack, Row, Col
	End
	Else
	Begin
		INSERT INTO T_Material_Locations( Tag,
		                                  Freezer,
		                                  Shelf,
		                                  Rack,
		                                  Row,
		                                  Col,
		                                  Status,
		                                  Barcode,
		                                  [Comment],
		                                  Container_Limit )
		SELECT Tag,
		       Freezer,
		       Shelf,
		       Rack,
		       Row,
		       Col,
		       Status,
		       Barcode,
		       [Comment],
		       Container_Limit
		FROM #Tmp_T_Material_Locations
		ORDER BY Shelf, Rack, Row, Col
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 
		begin
			set @message = 'Error adding rows to T_Material_Locations for freezer ' + @sourceFreezer
			RAISERROR (@message, 10, 1)
			return 51006
		end

		Set @message = 'Added ' + Cast(@myRowCount as varchar(12)) + ' rows to T_Material_Locations for freezer ' + @sourceFreezer

		Exec PostLogEntry 'Normal', @message, 'AddNewFreezer'
	End		

	---------------------------------------------------
	-- Done
	---------------------------------------------------
	--
	
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[AddNewFreezer] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddNewFreezer] TO [PNL\D3M580] AS [dbo]
GO
