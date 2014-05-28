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
**  Date:	10/29/2012 grk - Initial release
**			11/01/2012 grk - eliminated job template
**			01/31/2013 mem - Renamed MSGFDB to MSGFPlus
**			               - Updated error messages shown to user
**			02/13/2013 mem - Fix misspelled word
**			02/18/2013 mem - Fix misspelled word
**			08/13/2013 mem - Now validating required analysis tools for the MAC_iTRAQ script
**			08/14/2013 mem - Now validating datasets and jobs for script Global_Label-Free_AMT_Tag
**			04/20/2014 mem - Now mentioning ReporterTol param file when MASIC counts are not correct for an Isobaric_Labeling or MAC_iTRAQ script
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
	Set @tool = ''

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
		      MASIC INT NULL ,
		      MSGFPlus INT NULL ,
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
			MASIC = Tz.MASIC,
			MSGFPlus = Tz.MSGFPlus,
			Sequest = Tz.Sequest
		FROM #TX INNER JOIN 
		(
			SELECT  
				TPKG.Dataset,
				SUM(CASE WHEN TPKG.Tool = 'Decon2LS_V2' THEN 1 ELSE 0 END) AS Decon2LS_V2,
				SUM(CASE WHEN TPKG.Tool = 'MASIC_Finnigan' AND TD.[Parm File] LIKE '%ReporterTol%' THEN 1 ELSE 0 END) AS MASIC,
				SUM(CASE WHEN TPKG.Tool LIKE 'MSGFPlus%' THEN 1 ELSE 0 END) AS MSGFPlus,
				SUM(CASE WHEN TPKG.Tool LIKE 'Sequest%' THEN 1 ELSE 0 END) AS Sequest
			FROM    S_Data_Package_Analysis_Jobs AS TPKG
					INNER JOIN S_DMS_V_Analysis_Job_Info AS TD ON TPKG.Job = TD.Job
			WHERE   ( TPKG.Data_Package_ID = @DataPackageID )
			GROUP BY TPKG.Dataset
		) TZ ON #TX.Dataset = TZ.Dataset

		
		---------------------------------------------------
		-- assess job/tool coverage of datasets
		---------------------------------------------------

		DECLARE 
			@errMsg VARCHAR(4000) = '',
			@DeconToolsCountNotOne INT,
			@MasicCountNotOne INT,
			@MSGFPlusCountExactlyOne INT,
			@MSGFPlusCountNotOne INT,
			@SequestCountExactlyOne INT,
			@SequestCountNotOne INT

		SELECT @DeconToolsCountNotOne = COUNT(*) FROM #TX WHERE Decon2LS_V2 <> 1
		
		SELECT @MasicCountNotOne = COUNT(*) FROM #TX WHERE MASIC <> 1
		
		SELECT @MSGFPlusCountExactlyOne = COUNT(*) FROM #TX WHERE MSGFPlus = 1
		SELECT @MSGFPlusCountNotOne = COUNT(*) FROM #TX WHERE MSGFPlus <> 1
		
		SELECT @SequestCountExactlyOne = COUNT(*) FROM #TX WHERE Sequest = 1
		SELECT @SequestCountNotOne = COUNT(*) FROM #TX WHERE Sequest <> 1
		
		DROP TABLE  #TX

		if @scriptName Not In ('Global_Label-Free_AMT_Tag')
		Begin
			IF @tool = '' And @MSGFPlusCountExactlyOne > 0 
				If @MSGFPlusCountNotOne = 0
					SET @tool = 'msgfplus'
				Else
					SET @errMsg = 'Data package ' + Convert(varchar(12), @DataPackageID) + ' does not have exactly one MSGFPlus job for each dataset (' + Convert(varchar(12), @MSGFPlusCountNotOne) + ' invalid datasets); ' 
					
			IF @tool = '' And @SequestCountExactlyOne > 0
				If @SequestCountNotOne = 0
					SET @tool = 'sequest'
				Else
					SET @errMsg = 'Data package ' + Convert(varchar(12), @DataPackageID) + ' does not have exactly one Sequest job for each dataset (' + Convert(varchar(12), @SequestCountNotOne) + ' invalid datasets); ' 

			IF @tool = '' 
				SET @errMsg = @errMsg + 'Data package ' + Convert(varchar(12), @DataPackageID) + ' must have one or more MSGFPlus (or Sequest) jobs' 
		End
		
		---------------------------------------------------
		-- determine if job/tool coverage is acceptable for 
		-- given job template
		---------------------------------------------------
		
		IF @scriptName IN ('Isobaric_Labeling', 'MAC_iTRAQ')
		BEGIN 
			IF @DeconToolsCountNotOne > 0 
				SET @errMsg = @errMsg + 'There must be exactly one Decon2LS_V2 job per dataset; '
			
			IF @MasicCountNotOne > 0      
				SET @errMsg = @errMsg + 'There must be exactly one MASIC_Finnigan job per dataset (and that job must use a param file with ReporterTol in the name); '
		END 

		IF @scriptName IN ('Global_Label-Free_AMT_Tag')
		BEGIN 
			IF @DeconToolsCountNotOne > 0 
				SET @errMsg = @errMsg + 'There must be exactly one Decon2LS_V2 job per dataset; '
		END
		
		IF @errMsg <> ''
		BEGIN
	 		RAISERROR('Data package is not configured correctly for this job: %s', 11, 25, @errMsg)
		END 							

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH      
	return @myError

GO
