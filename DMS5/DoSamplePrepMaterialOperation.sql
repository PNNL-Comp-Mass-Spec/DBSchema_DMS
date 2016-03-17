/****** Object:  StoredProcedure [dbo].[DoSamplePrepMaterialOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoSamplePrepMaterialOperation
/****************************************************
**
**  Desc: 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	08/08/2008 grk - Initial version
**			02/23/2016 mem - Add set XACT_ABORT on
**
**
**	Note:
**		GRANT EXECUTE ON DoSamplePrepMaterialOperation TO [DMS_SP_User]    
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
(
	@ID varchar(128),
	@mode varchar(32),
	@message varchar(512) output,
	@callingUser varchar (128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int	
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	DECLARE @requestID INT
	SET @requestID = CONVERT(INT, @ID)
	
	DECLARE @comment varchar(512)
	
	SET @comment = 'Retired as part of closing sample prep request ' + @ID

	BEGIN TRY

		---------------------------------------------------
		-- get list of material items and containers for prep request
		---------------------------------------------------
		--
		if @mode = 'rowset' OR @mode = 'retire_items' OR @mode = 'retire_all'
		BEGIN
			-- temp table to hold list of material and containers for prep request
			CREATE TABLE #RTI (
			ID VARCHAR(32) NULL,
			ItemType VARCHAR(128),
			ItemName VARCHAR(128),
			CanRetire VARCHAR(64)
			)

			-- get biomaterial associated with the prep request
			INSERT INTO #RTI( ItemType,
				                ItemName,
				                CanRetire )
			SELECT 'Biomaterial' AS ItemName,
				    Biomaterial,
				    CASE
				        WHEN Biomaterial_Status = 'Active' THEN 'Yes'
				        ELSE 'No (material not Active)'
				    END AS CanRetire
			FROM V_Sample_Prep_Biomaterial_Location_List_Report
			WHERE ID = @requestID AND
				    NOT Container = 'na'
			
			-- get ID for biomaterial
		   UPDATE   #RTI
		   SET      ID = 'B:' + CONVERT(VARCHAR(32), TM.ID)
		   FROM     #RTI
			INNER JOIN ( SELECT CC_ID AS ID ,
								CC_Name AS Name
						 FROM   T_Cell_Culture
					   ) TM ON TM.NAME = #RTI.ItemName
			
			-- get containers holding the biomaterial
			INSERT INTO #RTI( ItemType,
				                ItemName,
				                CanRetire )
			SELECT DISTINCT 'Container' AS ItemName,
				            Container,
				            CASE
				                WHEN Container_Status = 'Active' THEN 'Yes'
				                ELSE 'No (container not Active)'
				            END AS CanRetire
			FROM V_Sample_Prep_Biomaterial_Location_List_Report
			WHERE ID = @requestID AND
				    NOT Container = 'na'
			
			-- get ID for containers
			 UPDATE #RTI
			 SET    ID = TM.ID
			 FROM   #RTI
			INNER JOIN ( SELECT ID ,
								Tag AS Name
						 FROM   T_Material_Containers
					   ) TM ON TM.NAME = #RTI.ItemName

			-- mark containers that hold foreign material
			UPDATE #RTI
			SET CanRetire = 'No (contains material not associated with this prep request)'
			FROM #RTI INNER join
			(
			SELECT  Container ,
					Item ,
					Item_Type
			FROM    V_Material_Items_List_Report
			WHERE   Container IN ( SELECT   ItemName
								   FROM     #RTI
								   WHERE    ItemType = 'Container' )
					AND ( ( Item_Type = 'Biomaterial'
							AND NOT ITEM IN ( SELECT    ItemName
											  FROM      #RTI
											  WHERE     ItemType = 'Biomaterial' )
						  )
						  OR Item_Type <> 'Biomaterial'
						)
			) T_Forn ON #RTI.ItemName = T_Forn.Container AND #RTI.ItemType = 'Container'

			-- get list of items
			DECLARE @itemList VARCHAR(4096)
			SET @itemList = ''
		   SELECT   @itemList = @itemList + CASE WHEN @itemList = '' THEN ''
												 ELSE ', '
											END + ID
		   FROM     #RTI
		   WHERE    ItemType = 'Biomaterial' AND CanRetire = 'Yes'

			-- get list of containers
			DECLARE @containerList VARCHAR(4096)
			SET @containerList = ''
		   SELECT   @containerList = @containerList + CASE WHEN @containerList = '' THEN ''
												 ELSE ', '
											END + ID
		   FROM     #RTI
		   WHERE    ItemType = 'Container' AND CanRetire = 'Yes'
	END

	---------------------------------------------------
	-- just return contents of working table
	---------------------------------------------------
	if @mode = 'rowset'
	BEGIN 
		SELECT ItemType, ItemName, CanRetire FROM #RTI
	END
	
	---------------------------------------------------
	-- retire material items
	---------------------------------------------------
	if (@mode = 'retire_items' OR @mode = 'retire_all') AND @itemList <> ''
	BEGIN
		exec @myError = UpdateMaterialItems
							'retire_items',
							@itemList,
							'mixed_material',
							'',
							@comment,
							@message output,
							@callingUser
		if @myError <> 0
			RAISERROR ('UpdateMaterialItems:%s', 11, 21, @message)
	END 

	---------------------------------------------------
	-- retire containers
	---------------------------------------------------
	if @mode = 'retire_all' AND @containerList <> ''
	BEGIN
		exec @myError = UpdateMaterialContainers
							'retire_container',
							@containerList,
							'',
							@comment,
							@message output,
							@callingUser

		if @myError <> 0
			RAISERROR ('UpdateMaterialContainers:%s', 11, 22, @message)
	END


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[DoSamplePrepMaterialOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoSamplePrepMaterialOperation] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoSamplePrepMaterialOperation] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoSamplePrepMaterialOperation] TO [PNL\D3M580] AS [dbo]
GO
