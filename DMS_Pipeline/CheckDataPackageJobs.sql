/****** Object:  UserDefinedFunction [dbo].[CheckDataPackageJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION CheckDataPackageJobs
/****************************************************
**
**  Desc: 
**  Returns a table
**
**  Return values: 
**
**  Parameters:
**	
**
**  Auth: grk
**  Date: 05/22/2010
**      
**    
*****************************************************/
(
@dataPackageID INT,
@scriptType1 VARCHAR(128),
@mode VARCHAR(32) = 'Jobs' -- DatasetsWithoutJobs DatasetsWithMultipleJobs 
)
RETURNS @theTable TABLE (
		Dataset VARCHAR(128),
		Job INT NULL
	)
AS
BEGIN
	---------------------------------------------------
	-- get list of datasets from given data package
	---------------------------------------------------
	--
	DECLARE @datasetList TABLE (
		Dataset VARCHAR(128),
		Dataset_ID INT,
		Job_Count INT NULL
	)
	--
	INSERT INTO @datasetList
        ( Dataset, Dataset_ID )
	SELECT DISTINCT
	  Dataset,
	  Dataset_ID
	FROM
	  S_Data_Package_Datasets -- DMS_Data_Package.dbo.T_Data_Package_Datasets -- 
	WHERE
	  Data_Package_ID = @dataPackageID

	---------------------------------------------------
	-- get list of jobs with script of @scriptType1
	-- for datasets in list
	---------------------------------------------------
	--
	DECLARE @jobList TABLE (
		Job INT,
		Tool VARCHAR(64),
		Dataset VARCHAR(128),
		[State] INT NULL 
	)
	--
	INSERT INTO @jobList
	( Job, Tool, Dataset)
	SELECT
		Job,
		ToolName AS Tool,
		Dataset
	FROM
		DMS5.dbo.V_GetPipelineJobParameters-- S_DMS_V_GetPipelineJobParameters
	WHERE
		Dataset IN ( SELECT Dataset FROM @datasetList )
		AND ToolName = @scriptType1

	---------------------------------------------------
	--
	---------------------------------------------------
	--
	UPDATE TL
		SET Job_Count = ISNULL(Tx.N, 0)
	FROM 
		@datasetList TL
		LEFT OUTER JOIN (
			SELECT
				Dataset,
				COUNT(*) AS N
			FROM
				@jobList
			GROUP BY
				Dataset
		) TX ON TL.Dataset = TX.Dataset

	---------------------------------------------------
	--
	---------------------------------------------------
	--
	IF @mode = 'JobsNotAlreadyInPackage'
	BEGIN 
		DELETE FROM
			@jobList
		WHERE
			Job IN ( 
				SELECT
					Job
				FROM
					S_Data_Package_Analysis_Jobs
				WHERE
					Data_Package_ID = @dataPackageID 
			)
		SET @mode = 'Jobs'
	END 



	IF @mode = 'Jobs'
	BEGIN 
		INSERT INTO @theTable
			( Job, Dataset )
		SELECT 
			Job, Dataset 
		FROM 
			@jobList
	END 

	IF @mode = 'DatasetsWithJobCount'
	BEGIN 
		INSERT INTO @theTable
			( Dataset, Job )
		SELECT
			Dataset, Job_Count
		FROM
			@datasetList
	END 



	IF @mode = 'DatasetsWithoutJobs'
	BEGIN 
		INSERT INTO @theTable
			( Dataset, Job )
		SELECT
			Dataset, Job_Count
		FROM
			@datasetList
		WHERE
			Job_Count = 0
	END 

	IF @mode = 'DatasetsWithMultipleJobs'
	BEGIN 
		INSERT INTO @theTable
			( Dataset, Job )
		SELECT
			Dataset, Job_Count
		FROM
			@datasetList
		WHERE
			Job_Count > 1
	END 


	RETURN
END

GO
GRANT SELECT ON [dbo].[CheckDataPackageJobs] TO [DMS_SP_User] AS [dbo]
GO
