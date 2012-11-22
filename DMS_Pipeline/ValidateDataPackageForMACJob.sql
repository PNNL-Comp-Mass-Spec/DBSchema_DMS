/****** Object:  StoredProcedure [dbo].[ValidateDataPackageForMACJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ValidateDataPackageForMACJob
/****************************************************
**
**  Desc: 
**  Verify configuration and contents of a data package
**  suitable for running a given MAC job from job template 
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	
**  10/29/2012 grk - Initial release
**  11/01/2012 grk - eliminated job template
**
*****************************************************/
(
	@DataPackageID int,
	@scriptName varchar(64),	
	@tool VARCHAR(64) output,
	@mode VARCHAR(12) = 'add', 
	@message VARCHAR(512) output
)
AS
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0

	Set @DataPackageID = IsNull(@DataPackageID, 0)
	
	DECLARE @DebugMode tinyint = 0

	BEGIN TRY                
		---------------------------------------------------
		-- create table to hold data package datasets
		-- and job counts
		---------------------------------------------------

		CREATE TABLE #TX (
		      Dataset_ID INT ,
		      Dataset VARCHAR(256) ,
		      Decon2LS_V2 INT NULL ,
		      MASIC_Finnigan INT NULL ,
		      MSGFDB_MzXML INT NULL ,
		      Sequest INT NULL 
		    )

		---------------------------------------------------
		-- populate with package datasets
		---------------------------------------------------

		INSERT INTO #TX
		(Dataset_ID, Dataset)
		SELECT  DISTINCT 
			Dataset_ID ,
			Dataset
		FROM    S_Data_Package_Datasets AS TPKG
		WHERE   ( TPKG.Data_Package_ID = @DataPackageID )

		---------------------------------------------------
		-- determine job counts per dataset for required tools
		---------------------------------------------------

		UPDATE #TX
		SET 
			Decon2LS_V2 = TZ.Decon2LS_V2,
			MASIC_Finnigan = Tz.MASIC_Finnigan,
			MSGFDB_MzXML = Tz.MSGFDB_MzXML,
			Sequest = Tz.Sequest
		FROM #TX INNER JOIN 
		(
			SELECT  
				TPKG.Dataset,
				SUM(CASE WHEN TPKG.Tool = 'Decon2LS_V2' THEN 1 ELSE 0 END) AS Decon2LS_V2,
				SUM(CASE WHEN TPKG.Tool = 'MASIC_Finnigan' AND TD.[Parm File] LIKE '%ReporterTol%' THEN 1 ELSE 0 END) AS MASIC_Finnigan,
				SUM(CASE WHEN TPKG.Tool = 'MSGFDB_MzXML' THEN 1 ELSE 0 END) AS MSGFDB_MzXML,
				SUM(CASE WHEN TPKG.Tool = 'Sequest' THEN 1 ELSE 0 END) AS Sequest
			FROM    S_Data_Package_Analysis_Jobs AS TPKG
					INNER JOIN S_DMS_V_Analysis_Job_Info AS TD ON TPKG.Job = TD.Job
			WHERE   ( TPKG.Data_Package_ID = @DataPackageID )
			GROUP BY TPKG.Dataset
		) TZ ON #TX.Dataset = TZ.Dataset

		--SELECT * FROM #TX
		---------------------------------------------------
		-- assess job/tool coverage of datasets
		---------------------------------------------------

		DECLARE 
			@errMsg VARCHAR(4000) = '',
			@decon2lsCount INT,
			@masicCount INT,
			@msgfdbCount INT,
			@sequestCount INT,
			@msgfdb0Count INT,
			@sequest0Count INT

		SELECT @decon2lsCount = COUNT(*) FROM #TX WHERE Decon2LS_V2 <> 1
		SELECT @masicCount = COUNT(*) FROM #TX WHERE MASIC_Finnigan <> 1
		SELECT @msgfdbCount = COUNT(*) FROM #TX WHERE MSGFDB_MzXML <> 1
		SELECT @sequestCount = COUNT(*) FROM #TX WHERE Sequest <> 1
		SELECT @msgfdb0Count = COUNT(*) FROM #TX WHERE MSGFDB_MzXML <> 0
		SELECT @sequest0Count = COUNT(*) FROM #TX WHERE Sequest <> 0

		IF @msgfdbCount = 0 AND @sequest0Count = 0
		SET @tool = 'msgfdb'
		ELSE
		IF @sequestCount = 0 AND @msgfdb0Count = 0
		SET @tool = 'sequest'

		DROP TABLE  #TX

		---------------------------------------------------
		-- determine of job/tool coverage is acceptable for 
		-- given job template
		---------------------------------------------------
		
		IF @scriptName IN ('MAC_Simple_Isobaric_Labelling')
		BEGIN 
			IF @tool = '' SET @errMsg = @errMsg + 'There must be exactly one MSGFDB_MzXML job per dataset or one Sequest job per dataset; ' 
			IF @decon2lsCount > 0 SET @errMsg = @errMsg + 'There must be exactly one Decon2LS_V2 job per dataset; '
			IF @masicCount > 0 SET @errMsg = @errMsg + 'There must be exactly one MASIC_Finnigan job per dataset; '
			IF @errMsg <> ''
			BEGIN
	 			RAISERROR('Data pckage is not configurated correctly for this job: %s', 11, 25, @errMsg)
			END 							
		END 

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH      
	return @myError
GO
