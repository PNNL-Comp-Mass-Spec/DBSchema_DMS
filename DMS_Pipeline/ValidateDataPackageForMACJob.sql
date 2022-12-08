/****** Object:  StoredProcedure [dbo].[ValidateDataPackageForMACJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateDataPackageForMACJob]
/****************************************************
**
**  Desc: 
**  Verify configuration and contents of a data package
**  suitable for running a given MAC job from job template 
**    
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   10/29/2012 grk - Initial release
**          11/01/2012 grk - eliminated job template
**          01/31/2013 mem - Renamed MSGFDB to MSGFPlus
**                         - Updated error messages shown to user
**          02/13/2013 mem - Fix misspelled word
**          02/18/2013 mem - Fix misspelled word
**          08/13/2013 mem - Now validating required analysis tools for the MAC_iTRAQ script
**          08/14/2013 mem - Now validating datasets and jobs for script Global_Label-Free_AMT_Tag
**          04/20/2014 mem - Now mentioning ReporterTol param file when MASIC counts are not correct for an Isobaric_Labeling or MAC_iTRAQ script
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          11/15/2017 mem - Use AppendToText to combine strings
**                         - Include data package ID in log messages
**          01/11/2018 mem - Allow PRIDE_Converter jobs to have multiple MSGF+ jobs for each dataset
**          04/06/2018 mem - Allow Phospho_FDR_Aggregator jobs to have multiple MSGF+ jobs for each dataset
**          06/12/2018 mem - Send @maxLength to AppendToText
**          05/01/2019 mem - Fix typo counting SEQUEST jobs
**          03/09/2021 mem - Add support for MaxQuant
**          08/26/2021 mem - Add support for MSFragger
**          10/02/2021 mem - No longer require that DeconTools jobs exist for MAC_iTRAQ jobs (similarly, MAC_TMT10Plex jobs don't need DeconTools)
**          06/30/2022 mem - Use new parameter file column name
**          12/07/2022 mem - Include script name in the error message
**
*****************************************************/
(
    @dataPackageID int,
    @scriptName varchar(64),    
    @tool varchar(64) output,
    @mode varchar(12) = 'add', 
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @dataPackageID = IsNull(@dataPackageID, 0)
    Set @tool = ''

    Declare @debugMode tinyint = 0
    
    Begin Try                
        ---------------------------------------------------
        -- create table to hold data package datasets
        -- and job counts
        ---------------------------------------------------

        CREATE TABLE #Tmp_DataPackageItems (
              Dataset_ID INT ,
              Dataset varchar(256) ,
              Decon2LS_V2 INT NULL ,
              MASIC INT NULL ,
              MSGFPlus INT NULL ,
              SEQUEST INT NULL 
            )

        ---------------------------------------------------
        -- Populate with package datasets
        ---------------------------------------------------

        INSERT INTO #Tmp_DataPackageItems( Dataset_ID,
                                           Dataset )
        SELECT DISTINCT Dataset_ID,
                        Dataset
        FROM S_Data_Package_Datasets AS TPKG
        WHERE (TPKG.Data_Package_ID = @dataPackageID)

        ---------------------------------------------------
        -- Determine job counts per dataset for required tools
        ---------------------------------------------------

        UPDATE #Tmp_DataPackageItems
        Set 
            Decon2LS_V2 = TargetTable.Decon2LS_V2,
            MASIC = TargetTable.MASIC,
            MSGFPlus = TargetTable.MSGFPlus,
            SEQUEST = TargetTable.SEQUEST
        FROM #Tmp_DataPackageItems INNER JOIN 
        (
            SELECT  
                TPKG.Dataset,
                SUM(CASE WHEN TPKG.Tool = 'Decon2LS_V2' THEN 1 ELSE 0 END) AS Decon2LS_V2,
                SUM(CASE WHEN TPKG.Tool = 'MASIC_Finnigan' AND TD.[Param File] LIKE '%ReporterTol%' THEN 1 ELSE 0 END) AS MASIC,
                SUM(CASE WHEN TPKG.Tool LIKE 'MSGFPlus%' THEN 1 ELSE 0 END) AS MSGFPlus,
                SUM(CASE WHEN TPKG.Tool LIKE 'SEQUEST%' THEN 1 ELSE 0 END) AS SEQUEST
            FROM    S_Data_Package_Analysis_Jobs AS TPKG
                    INNER JOIN S_DMS_V_Analysis_Job_Info AS TD ON TPKG.Job = TD.Job
            WHERE   ( TPKG.Data_Package_ID = @dataPackageID )
            GROUP BY TPKG.Dataset
        ) TargetTable ON #Tmp_DataPackageItems.Dataset = TargetTable.Dataset

        
        ---------------------------------------------------
        -- Assess job/tool coverage of datasets
        ---------------------------------------------------

        Declare 
            @errMsg varchar(1024) = '',
            @datasetCount int,
            @deconToolsCountNotOne int,
            @masicCountNotOne int,
            @msgfPlusCountExactlyOne int,
            @msgfPlusCountNotOne int,
            @msgfPlusCountOneOrMore int,
            @sequestCountExactlyOne int,
            @sequestCountNotOne int,
            @sequestCountOneOrMore int

        SELECT @datasetCount = COUNT(*) FROM #Tmp_DataPackageItems

        SELECT @deconToolsCountNotOne = COUNT(*) FROM #Tmp_DataPackageItems WHERE Decon2LS_V2 <> 1
        
        SELECT @masicCountNotOne = COUNT(*) FROM #Tmp_DataPackageItems WHERE MASIC <> 1
        
        SELECT @msgfPlusCountExactlyOne = COUNT(*) FROM #Tmp_DataPackageItems WHERE MSGFPlus = 1
        SELECT @msgfPlusCountNotOne = COUNT(*) FROM #Tmp_DataPackageItems WHERE MSGFPlus <> 1
        SELECT @msgfPlusCountOneOrMore = COUNT(*) FROM #Tmp_DataPackageItems WHERE MSGFPlus >= 1
        
        SELECT @sequestCountExactlyOne = COUNT(*) FROM #Tmp_DataPackageItems WHERE SEQUEST = 1
        SELECT @sequestCountNotOne = COUNT(*) FROM #Tmp_DataPackageItems WHERE SEQUEST <> 1
        SELECT @sequestCountOneOrMore = COUNT(*) FROM #Tmp_DataPackageItems WHERE SEQUEST >= 1

        DROP TABLE #Tmp_DataPackageItems

        If @scriptName LIKE ('MaxQuant%') Or @scriptName LIKE ('MSFragger%')
        Begin
            If @datasetCount = 0
            Begin
                Set @errMsg = 'Data package currently does not have any datasets (script ' + @scriptName + ')';
            End
        End

        If Not @scriptName In ('Global_Label-Free_AMT_Tag') AND Not @scriptName LIKE ('MaxQuant%') AND Not @scriptName LIKE ('MSFragger%')
        Begin
            If @scriptName = 'PRIDE_Converter'
            Begin
                If @msgfPlusCountOneOrMore > 0
                    Set @tool = 'msgfplus'
                Else If @sequestCountOneOrMore > 0
                    Set @tool = 'sequest'
            End
   
            If @tool = '' And @msgfPlusCountOneOrMore > 0
            Begin
                If @msgfPlusCountNotOne = 0 And @msgfPlusCountExactlyOne = @msgfPlusCountOneOrMore
                    Set @tool = 'msgfplus'
                Else
                Begin
                    If @scriptName In ('Phospho_FDR_Aggregator')
                        -- Allow multiple MSGF+ jobs for each dataset
                        Set @tool = 'msgfplus'
                    Else
                        Set @errMsg = 'Data package does not have exactly one MSGFPlus job for each dataset (' + Convert(varchar(12), @msgfPlusCountNotOne) + ' invalid datasets); script ' + @scriptName
                End
            End

            If @tool = '' And @sequestCountOneOrMore > 0
            Begin
                If @sequestCountNotOne = 0 And @sequestCountExactlyOne = @sequestCountOneOrMore
                    Set @tool = 'sequest'
                Else
                Begin
                    If @scriptName In ('Phospho_FDR_Aggregator')
                        -- Allow multiple Sequest jobs for each dataset
                        Set @tool = 'sequest'
                    Else
                        Set @errMsg = 'Data package does not have exactly one Sequest job for each dataset (' + Convert(varchar(12), @sequestCountNotOne) + ' invalid datasets); script ' + @scriptName
                End
            End

            If @tool = ''
            Begin
                Set @errMsg = dbo.AppendToText(@errMsg, 'Data package must have one or more MSGFPlus (or Sequest) jobs; error validating script ' + @scriptName, 0, '; ', 1024)
            End
        End
        
        ---------------------------------------------------
        -- Determine if job/tool coverage is acceptable for 
        -- given job template
        ---------------------------------------------------
        
        If @scriptName IN ('Isobaric_Labeling')
        Begin 
            If @deconToolsCountNotOne > 0 
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one Decon2LS_V2 job per dataset for script ' + @scriptName, 0, '; ', 1024)
            
            If @masicCountNotOne > 0
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one MASIC_Finnigan job per dataset (and that job must use a param file with ReporterTol in the name) for script ' + @scriptName, 0, '; ', 1024)
        End 

        If @scriptName IN ('MAC_iTRAQ', 'MAC_TMT10Plex')
        Begin 
            If @masicCountNotOne > 0
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one MASIC_Finnigan job per dataset (and that job must use a param file with ReporterTol in the name) for script ' + @scriptName, 0, '; ', 1024)
        End 

        If @scriptName IN ('Global_Label-Free_AMT_Tag')
        Begin 
            If @deconToolsCountNotOne > 0
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one Decon2LS_V2 job per dataset for script ' + @scriptName, 0, '; ', 1024)
        End
        
        If @errMsg <> ''
        Begin
            Set @errMsg = 'Data package ' + Cast(@dataPackageID as varchar(12)) + ' is not configured correctly for this job: ' + @errMsg
             RAISERROR(@errMsg, 11, 25)
        End                             

    End Try
    Begin Catch 
        EXEC FormatErrorMessage @message output, @myError output
        Exec PostLogEntry 'Error', @message, 'ValidateDataPackageForMACJob'
        
        If @myError = 0
            Set @myError = 20000
        
    End Catch
    
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateDataPackageForMACJob] TO [DDL_Viewer] AS [dbo]
GO
