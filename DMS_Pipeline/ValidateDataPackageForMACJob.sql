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
**          05/01/2019 mem - Fix typo counting Sequest jobs
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

        CREATE TABLE #TX (
              Dataset_ID INT ,
              Dataset varchar(256) ,
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
        WHERE   ( TPKG.Data_Package_ID = @dataPackageID )

        ---------------------------------------------------
        -- Determine job counts per dataset for required tools
        ---------------------------------------------------

        UPDATE #TX
        Set 
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
            WHERE   ( TPKG.Data_Package_ID = @dataPackageID )
            GROUP BY TPKG.Dataset
        ) TZ ON #TX.Dataset = TZ.Dataset

        
        ---------------------------------------------------
        -- Assess job/tool coverage of datasets
        ---------------------------------------------------

        Declare 
            @errMsg varchar(1024) = '',
            @DeconToolsCountNotOne int,
            @MasicCountNotOne int,
            @MSGFPlusCountExactlyOne int,
            @MSGFPlusCountNotOne int,
            @MSGFPlusCountOneOrMore int,
            @SequestCountExactlyOne int,
            @SequestCountNotOne int,
            @SequestCountOneOrMore int

        SELECT @DeconToolsCountNotOne = COUNT(*) FROM #TX WHERE Decon2LS_V2 <> 1
        
        SELECT @MasicCountNotOne = COUNT(*) FROM #TX WHERE MASIC <> 1
        
        SELECT @MSGFPlusCountExactlyOne = COUNT(*) FROM #TX WHERE MSGFPlus = 1
        SELECT @MSGFPlusCountNotOne = COUNT(*) FROM #TX WHERE MSGFPlus <> 1
        SELECT @MSGFPlusCountOneOrMore = COUNT(*) FROM #TX WHERE MSGFPlus >= 1
        
        SELECT @SequestCountExactlyOne = COUNT(*) FROM #TX WHERE Sequest = 1
        SELECT @SequestCountNotOne = COUNT(*) FROM #TX WHERE Sequest <> 1
        SELECT @SequestCountOneOrMore = COUNT(*) FROM #TX WHERE Sequest >= 1

        DROP TABLE #TX

        If @scriptName Not In ('Global_Label-Free_AMT_Tag')
        Begin
            If @scriptName = 'PRIDE_Converter'
            Begin
                If @MSGFPlusCountOneOrMore > 0
                    Set @tool = 'msgfplus'
                Else If @SequestCountOneOrMore > 0
                    Set @tool = 'sequest'
            End
   
            If @tool = '' And @MSGFPlusCountOneOrMore > 0
            Begin
                If @MSGFPlusCountNotOne = 0 And @MSGFPlusCountExactlyOne = @MSGFPlusCountOneOrMore
                    Set @tool = 'msgfplus'
                Else
                Begin
                    If @scriptName In ('Phospho_FDR_Aggregator')
                        -- Allow multiple MSGF+ jobs for each dataset
                        Set @tool = 'msgfplus'
                    Else
                        Set @errMsg = 'Data package does not have exactly one MSGFPlus job for each dataset (' + Convert(varchar(12), @MSGFPlusCountNotOne) + ' invalid datasets)' 
                End
            End

            If @tool = '' And @SequestCountOneOrMore > 0
            Begin
                If @SequestCountNotOne = 0 And @SequestCountExactlyOne = @SequestCountOneOrMore
                    Set @tool = 'sequest'
                Else
                Begin
                    If @scriptName In ('Phospho_FDR_Aggregator')
                        -- Allow multiple Sequest jobs for each dataset
                        Set @tool = 'sequest'
                    Else
                        Set @errMsg = 'Data package does not have exactly one Sequest job for each dataset (' + Convert(varchar(12), @SequestCountNotOne) + ' invalid datasets)' 
                End
            End

            If @tool = ''
            Begin
                Set @errMsg = dbo.AppendToText(@errMsg, 'Data package must have one or more MSGFPlus (or Sequest) jobs', 0, '; ', 1024)
            End
        End
        
        ---------------------------------------------------
        -- Determine if job/tool coverage is acceptable for 
        -- given job template
        ---------------------------------------------------
        
        If @scriptName IN ('Isobaric_Labeling', 'MAC_iTRAQ')
        Begin 
            If @DeconToolsCountNotOne > 0 
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one Decon2LS_V2 job per dataset', 0, '; ', 1024)
            
            If @MasicCountNotOne > 0
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one MASIC_Finnigan job per dataset (and that job must use a param file with ReporterTol in the name)', 0, '; ', 1024)
        End 

        If @scriptName IN ('Global_Label-Free_AMT_Tag')
        Begin 
            If @DeconToolsCountNotOne > 0
                Set @errMsg = dbo.AppendToText(@errMsg, 'There must be exactly one Decon2LS_V2 job per dataset', 0, '; ', 1024)
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
