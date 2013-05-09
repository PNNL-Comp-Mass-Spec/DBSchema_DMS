/****** Object:  StoredProcedure [dbo].[UpdateOSMPackageItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateOSMPackageItems]
/****************************************************
**
**	Desc:
**      Updates data package items in list according to command mode
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**    Auth: grk
**    Date: 
**          10/22/2012 grk - initial release
**          10/25/2012 grk - added debugging
**          11/01/2012 grk - added datasets and requested runs
**          12/12/2012 grk - now updating OSM package change date
**          03/20/2013 grk - added auto-import mode
**          04/09/2013 grk - fixed bug with marking items as already in package
**
*****************************************************/
(
	@packageID int,
	@itemType varchar(128),
	@itemList text,
	@comment varchar(512),
	@mode varchar(12) = 'update',
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	declare @wasModified tinyint
	set @wasModified = 0
	  
	---------------------------------------------------
	-- Test mode for debugging
	---------------------------------------------------
	if @mode = 'Test'
	begin
		set @message = 'Test Mode'
		return 1
	end

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 					
		---------------------------------------------------	
		-- staging table			
		---------------------------------------------------	
		CREATE TABLE #TPI(
			OSM_Package_ID INT NOT NULL,
			Item_ID INT NULL,
			Item VARCHAR(512) NULL,
			Item_Type VARCHAR(64) NULL,
			Comment VARCHAR(512) NULL,
			InDMS TINYINT NULL,
			InPackage TINYINT NULL 	
		)
		---------------------------------------------------
		-- initial load of staging table from item list
		---------------------------------------------------	
		
		IF @mode = 'auto-import'
		BEGIN --<a>
			SET @mode = 'add'
			EXEC GetAutoImportOSMPackageItems @packageID, @message OUTPUT 
			UPDATE #TPI SET Comment = 'Automatically imported', InDMS = 0, InPackage = 0
		END --<a>
		ELSE 
		BEGIN --<b>
			IF @itemType IN ('Sample_Prep_Requests', 'Experiment_Groups', 'HPLC_Runs', 'Sample_Submissions', 'Requested_Runs')
			BEGIN
				INSERT INTO #TPI(OSM_Package_ID, Item_ID, Item_Type, Comment, InDMS, InPackage) 
				SELECT @packageID, Item, @itemType, @comment, 0, 0  FROM MakeTableFromText(@itemList)
			END	
			ELSE
			BEGIN
				INSERT INTO #TPI(OSM_Package_ID, Item, Item_Type, Comment, InDMS, InPackage) 
				SELECT @packageID, Item, @itemType, @comment, 0, 0 FROM MakeTableFromText(@itemList)
			END	
		END --<b>

	
		---------------------------------------------------
		-- population of staging table from DMS entities
		---------------------------------------------------	

		IF 'Sample_Submissions' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item = TS.Item, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT ID AS Item_ID, 
					CASE WHEN LEN(ISNULL([Description], '')) > 128 THEN CONVERT(VARCHAR(125), ISNULL([Description], '')) + '...'	ELSE ISNULL([Description], '') END AS Item
					FROM   S_Sample_Submission_List
				) TS ON #TPI.Item_ID = TS.Item_ID		
		END

		IF 'Sample_Prep_Requests' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item = TS.Item, InDMS = 1
			FROM #TPI
			INNER JOIN (
				SELECT ID AS Item_ID, ISNULL(Request_Name, '') AS Item
				FROM S_Sample_Prep_Request_List
				) TS ON #TPI.Item_ID =  TS.Item_ID		
		END

		IF 'Material_Containers' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item_ID = TS.Item_ID, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT ID AS Item_ID, Tag AS Item
					FROM S_Material_Containers_List
				) TS ON #TPI.Item = TS.Item		
		END

		IF 'HPLC_Runs' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item = TS.Item, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT ID AS Item_ID, Tab AS Item
					FROM S_Prep_LC_Run_List
				) TS ON #TPI.Item_ID =  TS.Item_ID		
		END

		IF 'Experiments' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item_ID = TS.Item_ID, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT Exp_ID AS Item_ID, Experiment_Num AS Item
					FROM S_Experiment_List
				) TS ON #TPI.Item = TS.Item		
		END

		IF 'Experiment_Groups' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item = TS.Item, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT Group_ID AS Item_ID, 
					CASE WHEN LEN(EG_Description) > 512 THEN CONVERT(varchar(512), EG_Description) ELSE ISNULL(EG_Description, '') END  AS Item
					FROM S_Experiment_Groups_List
				) TS ON #TPI.Item_ID =  TS.Item_ID		
		END

		IF 'Requested_Runs' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item = TS.Item, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT ID AS Item_ID, RDS_Name AS Item
					FROM S_Requested_Run
				) TS ON #TPI.Item_ID = TS.Item_ID		
		END

		IF 'Datasets' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item_ID = TS.Item_ID, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT Dataset_ID AS Item_ID, Dataset_Num AS Item
					FROM S_Dataset
				) TS ON #TPI.Item = TS.Item		
		END

		IF 'Campaigns' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item_ID = TS.Item_ID, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT Campaign_ID AS Item_ID, Campaign_Num AS Item
					FROM  S_Campaign_List
				) TS ON #TPI.Item = TS.Item		
		END

		IF 'Biomaterial' IN (SELECT DISTINCT Item_Type FROM #TPI)
		BEGIN
			UPDATE #TPI
			SET Item_ID = TS.Item_ID, InDMS = 1
			FROM #TPI
			INNER JOIN (
					SELECT CC_ID AS Item_ID, CC_Name AS Item
					FROM S_Biomaterial_List
				) TS ON #TPI.Item = TS.Item		
		END

 		---------------------------------------------------
 		-- mark items in staging table that are alread in package
 		---------------------------------------------------
 	
		UPDATE #TPI
		SET InPackage = 1
		FROM #TPI
		INNER JOIN T_OSM_Package_Items OPI ON #TPI.Item_ID = OPI.Item_ID
											  AND #TPI.OSM_Package_ID = OPI.OSM_Package_ID
											  AND #TPI.Item_Type = OPI.Item_Type

 		---------------------------------------------------
 		-- Take a look at the counts
 		---------------------------------------------------

		DECLARE 
			@numItems INT = 0,
			@numInDMS INT = 0,
			@numInPackage INT = 0	
		SELECT @numItems = COUNT(*) FROM #TPI
		SELECT @numInDMS = COUNT(*) FROM #TPI WHERE InDMS > 0
		SELECT @numInPackage= COUNT(*) FROM #TPI WHERE InPackage > 0
		
 		---------------------------------------------------
 		-- add new items to package
 		---------------------------------------------------
 		
		IF @mode = 'add' AND @numItems > 0
		BEGIN --<add>
			IF @numInDMS <> @numItems
				RAISERROR('Invalid identifiers:(%d/%d)', 11, 14, @numInDMS, @numItems)	
		
			INSERT INTO dbo.T_OSM_Package_Items ( 
				OSM_Package_ID ,
				Item_ID ,
				Item ,
				Item_Type ,
				[Package Comment]
			)
			SELECT 
				OSM_Package_ID,
				Item_ID,
				Item,
				Item_Type,
				Comment
			FROM #TPI WHERE InPackage = 0	        
		END --<add>

 		---------------------------------------------------
 		-- remove designated items from package
 		---------------------------------------------------
 		
		IF @mode = 'delete' AND @numInPackage > 0
		BEGIN --<delete>
			DELETE FROM T_OSM_Package_Items	
			WHERE Item_Type = @itemType 
			AND OSM_Package_ID = @packageID			                      
			AND Item_ID IN (SELECT Item_ID FROM #TPI WHERE InPackage > 0)			
		END --<delete>

 		---------------------------------------------------
 		-- update item counts
 		---------------------------------------------------

		if @mode IN ('add', 'delete')
		BEGIN --<uc>
			EXEC UpdateOSMPackageItemCount @packageID
		END --<uc>

		if @mode = 'debug'
		BEGIN --<db>
			SELECT * FROM #TPI
			
			SELECT @numItems AS NumItems
			SELECT @numInDMS AS NumInDMS
			SELECT @numInPackage AS NumInPackage	
			
		END --<db>
       
 	---------------------------------------------------
 	---------------------------------------------------

	END TRY     
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError




GO
GRANT EXECUTE ON [dbo].[UpdateOSMPackageItems] TO [DMS_SP_User] AS [dbo]
GO
