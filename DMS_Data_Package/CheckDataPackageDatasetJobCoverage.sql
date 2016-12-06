/****** Object:  UserDefinedFunction [dbo].[CheckDataPackageDatasetJobCoverage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.CheckDataPackageDatasetJobCoverage
/****************************************************
**
**  Desc: 
**  Returns a table
**
**  Return values: 
**
**  Parameters:
**	
**  Auth: grk
**  Date: 05/22/2010
**    
*****************************************************/
(
	@packageID INT,
	@tool VARCHAR(128),
	@mode VARCHAR(32)
)
RETURNS @table_variable TABLE (Dataset VARCHAR(128), Num int)
AS
	BEGIN

	-- package datasets with no package jobs for tool
	--
	IF @mode = 'NoPackageJobs'
	BEGIN 
		INSERT INTO @table_variable
			( Dataset, Num )
		SELECT
		  Dataset, NULL AS Num
		FROM
		  T_Data_Package_Datasets AS TD
		WHERE
		  ( Data_Package_ID = @packageID )
		  AND ( NOT EXISTS ( SELECT
							  Dataset
							 FROM
							  T_Data_Package_Analysis_Jobs AS TA
							 WHERE
							  ( Tool = @tool )
							  AND ( TD.Dataset = Dataset )
							  AND ( TD.Data_Package_ID = Data_Package_ID ) )
			  )
	END
		  
		-- package datasets with no dms jobs for tool
		--
	IF @mode = 'NoDMSJobs'
	BEGIN 
		INSERT INTO @table_variable
			( Dataset, Num )
		SELECT
		  Dataset, NULL AS Num
		FROM
		  T_Data_Package_Datasets AS TD
		WHERE
		  ( Data_Package_ID = @packageID )
		  AND ( NOT EXISTS ( SELECT
							  Dataset
							 FROM
							  S_V_Analysis_Job_List_Report_2 AS TA
							 WHERE
							  ( Tool = @tool )
							  AND ( TD.Dataset = Dataset )
							  AND ( TD.Data_Package_ID = Data_Package_ID ) )
		  )
	END
  
	IF @mode = 'PackageJobCount'
	BEGIN 
		INSERT INTO @table_variable
			( Dataset, Num )
		SELECT
		  TD.Dataset,
		  SUM(CASE WHEN TA.Job IS NULL THEN 0
				   ELSE 1
			  END) AS Num
		FROM
		  T_Data_Package_Datasets AS TD
		  LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS TA ON TD.Dataset = TA.Dataset
																AND TD.Data_Package_ID = TA.Data_Package_ID

		GROUP BY
		  TD.Data_Package_ID,
		  TD.Dataset,
		  TA.Tool
		HAVING
		  TD.Data_Package_ID = @packageID 
		  AND TA.Tool = @tool
		END

	RETURN
	END

GO
GRANT VIEW DEFINITION ON [dbo].[CheckDataPackageDatasetJobCoverage] TO [DDL_Viewer] AS [dbo]
GO
