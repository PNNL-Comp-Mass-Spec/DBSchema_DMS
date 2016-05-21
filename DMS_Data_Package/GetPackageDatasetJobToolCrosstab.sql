/****** Object:  StoredProcedure [dbo].[GetPackageDatasetJobToolCrosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetPackageDatasetJobToolCrosstab
/****************************************************
**
**  Desc:
**  Crosstab of data package datasets against job count per tool
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	05/26/2010 grk - Initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**			05/18/2016 mem - Log errors to T_Log_Entries
**    
*****************************************************/
(
	@DataPackageID INT,
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY

		---------------------------------------------------
		-- temp tables
		---------------------------------------------------
		--
		Create TABLE #Tools (
		Tool varchar(128)
		)
		--
		CREATE TABLE #Scratch  (
			Dataset VARCHAR(128),
			Total INT
		)
		--
		CREATE TABLE #Datasets (
			Dataset VARCHAR(128),
			Jobs INT NULL,
			#ID INT
		)
		---------------------------------------------------
		-- get list of package datasets
		---------------------------------------------------
		--
		INSERT INTO #Datasets
			( Dataset, #ID)
		SELECT DISTINCT Dataset, @DataPackageID
		FROM T_Data_Package_Datasets 
		WHERE Data_Package_ID = @DataPackageID
		
		-- update job counts
		UPDATE #Datasets
		SET Jobs = TX.Total
		FROM #Datasets
		INNER JOIN 
		(
				SELECT Dataset, COUNT(*) AS Total
				FROM T_Data_Package_Analysis_Jobs
				WHERE Data_Package_ID = @DataPackageID
				GROUP BY Dataset
		)TX ON TX.Dataset = #Datasets.Dataset

		---------------------------------------------------
		-- get list of tools covered by package jobs
		---------------------------------------------------
		--
		INSERT INTO #Tools 
		( Tool )
		SELECT DISTINCT
		  Tool
		FROM
		  T_Data_Package_Analysis_Jobs
		WHERE
		  Data_Package_ID = @DataPackageID
		  

		---------------------------------------------------
		-- add cols to temp dataset table for each tool
		-- and update it with package job count
		---------------------------------------------------
		DECLARE 
		@colName VARCHAR(128) = 0,
		@done TINYINT = 0,
		@s NVARCHAR(1000)

		WHILE @done = 0
		BEGIN --<a>
		SET @colName = ''
			SELECT TOP 1 @colName = Tool FROM #Tools 
			IF @colName = ''
				SET @done = 1
			ELSE
			BEGIN --<b>
				DELETE FROM #Tools WHERE Tool = @colName
			
				SET @s = REPLACE('ALTER TABLE #Datasets ADD @col@ INT NULL', '@col@', @colName)
				EXEC(@s)
				
				DELETE FROM #Scratch
				--
				INSERT INTO #Scratch
				( Dataset, Total )
				SELECT Dataset, COUNT(*) AS Total
				FROM T_Data_Package_Analysis_Jobs
				WHERE Data_Package_ID = @DataPackageID AND Tool = @colName
				GROUP BY Dataset

				SET @s = REPLACE('UPDATE #Datasets SET @col@ = TX.Total FROM #Datasets INNER JOIN #Scratch TX ON TX.Dataset = #Datasets.Dataset', '@col@', @colName)
				EXEC(@s)
			
			END --<b>
		END --<a>
		
		SELECT * FROM #Datasets
		
		---------------------------------------------------
		--
		---------------------------------------------------
		--
		DROP TABLE #Tools
		DROP TABLE #Scratch
		DROP TABLE #Datasets

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		Exec PostLogEntry 'Error', @msgForLog, 'GetPackageDatasetJobToolCrosstab'
		
	END CATCH

	RETURN @myError


GO
GRANT EXECUTE ON [dbo].[GetPackageDatasetJobToolCrosstab] TO [DMS_SP_User] AS [dbo]
GO
