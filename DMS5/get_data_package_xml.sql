/****** Object:  UserDefinedFunction [dbo].[GetDataPackageXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetDataPackageXML]
/****************************************************
**
**  Desc:
**      Get XML description of data package contents
**
**  Auth:   grk
**  Date:   04/25/2012
**          05/06/2012 grk - Added support for experiments
**          06/08/2022 mem - Rename package type field to Package_Type
**                         - Rename package comment field to Package_Comment
**          06/18/2022 mem - Add support for returning XML for all of the sections by setting @options to 'All'
**
*****************************************************/
(
    @DataPackageID INT,
    @options VARCHAR(256) -- 'Parameters', 'Experiments', 'Datasets', 'Jobs', 'Paths', or 'All'
)
RETURNS VARCHAR(MAX)
AS
BEGIN

    DECLARE @result VARCHAR(MAX) = ''
    DECLARE @crlf VARCHAR(2) = CHAR(13)

    Declare @includeAll Tinyint

    Set @options = LTrim(RTrim(Coalesce(@options, '')))

    If @options = '' Or @options = 'All'
        Set @includeAll = 1;
    Else
        Set @includeAll = 0;

    SET @result = @result + '<data_package>'  + @crlf

    ---------------------------------------------------
    -- data package parameters
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Parameters', @options) > 0
    BEGIN --<a>
        SET @result = @result + '<general>' + @crlf

        DECLARE @paramXML XML
        SET @paramXML = (
        SELECT  ID,
                Name,
                Description,
                Owner,
                Team,
                State,
                Package_Type AS PackageType,
                Requester,
                Total,
                Jobs,
                Datasets,
                Experiments,
                Biomaterial,
                CONVERT(VARCHAR(24), Created, 101) AS Created
        FROM    S_V_Data_Package_Export AS package
        WHERE   ID = @DataPackageID
        FOR     XML AUTO, TYPE
        )

        SET @result = @result + CONVERT(VARCHAR(MAX), @paramXML)

        SET @result = @result + @crlf + '</general>' + @crlf
    END --<a>

    ---------------------------------------------------
    -- experiment details
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Experiments', @options) > 0
    BEGIN --<e>
        SET @result = @result + @crlf + '<experiments>' + @crlf

        DECLARE @experimentXML XML
        SET @experimentXML = (
        SELECT * FROM (
            SELECT
                    Experiment_ID,
                    Experiment,
                    TRG.OG_name AS Organism,
                    TC.Campaign_Num AS Campaign,
                    Created,
                    TEX.EX_reason AS Reason,
                    Package_Comment
            FROM     S_V_Data_Package_Experiments_Export AS TDPE
            INNER JOIN T_Experiments TEX ON TDPE.Experiment_ID = TEX.Exp_ID
            INNER JOIN T_Campaign TC ON TC.Campaign_ID = TEX.EX_campaign_ID
            INNER JOIN dbo.T_Organisms TRG ON TRG.Organism_ID = TEX.EX_organism_ID
            WHERE   TDPE.Data_Package_ID = @DataPackageID
            ) experiment
        FOR XML AUTO, TYPE
        )
        SET @result = @result + CONVERT(VARCHAR(MAX), @experimentXML)

        SET @result = @result + @crlf + '</experiments>' + @crlf
    END --<e>

    ---------------------------------------------------
    -- dataset details
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Datasets', @options) > 0
    BEGIN --<d>
        SET @result = @result + @crlf + '<datasets>' + @crlf

        DECLARE @datasetXML XML
        SET @datasetXML = (
        SELECT * FROM (
            SELECT  DS.Dataset_ID,
                    Dataset,
                    -- Experiment,
                    DS.Exp_ID as Experiment_ID,
                    Instrument,
                    Created,
                    Package_Comment
            FROM    S_V_Data_Package_Datasets_Export AS TDPD
                    INNER JOIN T_Dataset AS DS ON DS.Dataset_ID = TDPD.Dataset_ID
            WHERE   TDPD.Data_Package_ID = @DataPackageID
            ) dataset
        FOR XML AUTO, TYPE
        )
        SET @result = @result + CONVERT(VARCHAR(MAX), @datasetXML)

        SET @result = @result + @crlf + '</datasets>' + @crlf
    END --<d>

    ---------------------------------------------------
    -- job details
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Jobs', @options) > 0
    BEGIN --<b>
        SET @result = @result + @crlf + '<jobs>' + @crlf

        DECLARE @jobXML XML
        SET @jobXML = (
        SELECT * FROM (
            SELECT  VMA.Job,
                    VMA.Dataset_ID,
                    VMA.Tool,
                    VMA.Parameter_File,
                    VMA.Settings_File,
                    VMA.[Protein Collection List] AS Protein_Collection_List,
                    VMA.[Protein Options] As Protein_Options,
                    VMA.Comment,
                    VMA.State,
                    DPJ.Package_Comment
            FROM  S_V_Data_Package_Analysis_Jobs_Export AS DPJ
                    INNER JOIN V_Mage_Analysis_Jobs AS VMA  ON VMA.Job = DPJ.Job
            WHERE DPJ.Data_Package_ID = @DataPackageID
            ) job
        FOR XML AUTO, TYPE
        )
        SET @result = @result + CONVERT(VARCHAR(MAX), @jobXML)

        SET @result = @result + @crlf + '</jobs>' + @crlf
    END --<b>

    ---------------------------------------------------
    -- job archive paths
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Paths', @options) > 0
    BEGIN --<c>

        SET @result = @result + @crlf + '<paths>'

        ---------------------------------------------------
        -- data package path
        ---------------------------------------------------

        DECLARE @dpPathXML XML
        SET @dpPathXML = (
            SELECT
                    REPLACE(Storage_Path_Relative, '\', '/') AS Storage_Path
            FROM    S_V_Data_Package_Export AS data_package_path
            WHERE   ID = @DataPackageID
            FOR     XML AUTO, TYPE
        )
        SET @result = @result + @crlf
        SET @result = @result + '<!-- copy this folder and its contents -->' + @crlf
        SET @result = @result + CONVERT(VARCHAR(MAX), @dpPathXML)

        ---------------------------------------------------
        -- dataset paths
        ---------------------------------------------------

        DECLARE @dsPathXML XML
        SET @dsPathXML = (
        SELECT * FROM (
            SELECT  DS.Dataset_ID,
                    ISNULL(AP.AP_archive_path, '') + '/' +
                    ISNULL(DS.DS_folder_name, DS.Dataset_Num) AS Folder_Path
            FROM    S_V_Data_Package_Datasets_Export AS TDPD
                    INNER JOIN T_Dataset AS DS ON DS.Dataset_ID = TDPD.Dataset_ID
                    INNER JOIN T_Dataset_Archive AS DA ON DA.AS_Dataset_ID = DS.Dataset_ID
                    INNER JOIN T_Archive_Path AS AP ON AP.AP_path_ID = DA.AS_storage_path_ID
            WHERE   TDPD.Data_Package_ID = @DataPackageID
            ) dataset_path
        FOR XML AUTO, TYPE
        )
        SET @result = @result + @crlf + @crlf
        SET @result = @result + '<!-- Copy the each dataset folder and its file contents -->' + @crlf
        SET @result = @result + '<!-- (do not copy any subfolders). -->' + @crlf
        SET @result = @result + CONVERT(VARCHAR(MAX), @dsPathXML)

        ---------------------------------------------------
        -- job paths
        ---------------------------------------------------

        DECLARE @jobPathXML XML
        SET @jobPathXML = (
        SELECT * FROM (
            SELECT  --TDPA.Data_Package_ID,
                    DPJ.Job,
                    -- TDPA.Tool,
                    ISNULL(AP.AP_archive_path, '') + '/' +
                    ISNULL(TDS.DS_folder_name, TDS.Dataset_Num) + '/' +
                    ISNULL(AJ.AJ_resultsFolderName, '') AS Folder_Path
            FROM    S_V_Data_Package_Analysis_Jobs_Export AS DPJ
                    INNER JOIN T_Dataset AS TDS ON TDS.Dataset_Num = DPJ.Dataset
                    INNER JOIN T_Dataset_Archive AS DA ON DA.AS_Dataset_ID = TDS.Dataset_ID
                    INNER JOIN T_Archive_Path AS AP ON AP.AP_path_ID = DA.AS_storage_path_ID
                    INNER JOIN T_Analysis_Job AS AJ ON AJ.AJ_jobID = DPJ.Job
            WHERE DPJ.Data_Package_ID = @DataPackageID
            ) job_path
        FOR XML AUTO, TYPE
        )
        SET @result = @result + @crlf + @crlf
        SET @result = @result + '<!-- Copy each job results folder and its contents -->' + @crlf
        SET @result = @result + CONVERT(VARCHAR(MAX), @jobPathXML)

        SET @result = @result + @crlf + '</paths>' + @crlf
    END --<c>

    SET @result = @result + @crlf + '</data_package>'

    RETURN @result
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetDataPackageXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDataPackageXML] TO [DMS2_SP_User] AS [dbo]
GO
