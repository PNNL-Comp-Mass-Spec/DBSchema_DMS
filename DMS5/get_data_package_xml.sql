/****** Object:  UserDefinedFunction [dbo].[get_data_package_xml] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_data_package_xml]
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
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/22/2023 mem - Use lowercase attribute names
**                         - Coalesce null values to empty strings          
**
*****************************************************/
(
    @dataPackageID INT,
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
    -- Data package parameters
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Parameters', @options) > 0
    BEGIN --<a>
        SET @result = @result + '<general>' + @crlf

        DECLARE @paramXML XML
        SET @paramXML = (
        SELECT id,
               name,
               description,
               owner,
               team,
               state,
               package_type,
               Coalesce(requester, '') AS requester,
               total,
               jobs,
               datasets,
               experiments,
               biomaterial,
               CONVERT(VARCHAR(24), Created, 101) AS created
        FROM S_V_Data_Package_Export AS package
        WHERE ID = @DataPackageID
        FOR XML AUTO, TYPE
        )

        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @paramXML), '')

        SET @result = @result + @crlf + '</general>' + @crlf
    END --<a>

    ---------------------------------------------------
    -- Experiment details
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Experiments', @options) > 0
    BEGIN --<e>
        SET @result = @result + @crlf + '<experiments>' + @crlf

        DECLARE @experimentXML XML
        SET @experimentXML = (
        SELECT * FROM (
            SELECT DPE.experiment_id,
                   DPE.experiment,
                   TRG.OG_name AS organism,
                   TC.Campaign_Num AS campaign,
                   DPE.created,
                   Coalesce(TEX.EX_reason, '') AS reason,
                   Coalesce(DPE.package_comment, '') AS package_comment
            FROM S_V_Data_Package_Experiments_Export AS DPE
                 INNER JOIN T_Experiments TEX ON DPE.Experiment_ID = TEX.Exp_ID
                 INNER JOIN T_Campaign TC ON TC.Campaign_ID = TEX.EX_campaign_ID
                 INNER JOIN dbo.T_Organisms TRG ON TRG.Organism_ID = TEX.EX_organism_ID
            WHERE DPE.Data_Package_ID = @DataPackageID
            ) experiment
        FOR XML AUTO, TYPE
        )
        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @experimentXML), '')

        SET @result = @result + @crlf + '</experiments>' + @crlf
    END --<e>

    ---------------------------------------------------
    -- Dataset details
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Datasets', @options) > 0
    BEGIN --<d>
        SET @result = @result + @crlf + '<datasets>' + @crlf

        DECLARE @datasetXML XML
        SET @datasetXML = (
        SELECT * FROM (
            SELECT DS.dataset_id,
                   DPD.dataset,
                   -- DPD.experiment,
                   DS.Exp_ID AS experiment_id,
                   DPD.instrument,
                   DPD.created,
                   Coalesce(DPD.Package_Comment, '') AS package_comment
            FROM S_V_Data_Package_Datasets_Export AS DPD
                 INNER JOIN T_Dataset AS DS ON DS.Dataset_ID = DPD.Dataset_ID
            WHERE DPD.Data_Package_ID = @DataPackageID
            ) dataset
        FOR XML AUTO, TYPE
        )
        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @datasetXML), '')

        SET @result = @result + @crlf + '</datasets>' + @crlf
    END --<d>

    ---------------------------------------------------
    -- Job details
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Jobs', @options) > 0
    BEGIN --<b>
        SET @result = @result + @crlf + '<jobs>' + @crlf

        DECLARE @jobXML XML
        SET @jobXML = (
        SELECT * FROM (
            SELECT VMA.job,
                   VMA.dataset_id,
                   VMA.tool,
                   VMA.parameter_file,
                   VMA.settings_file,
                   Coalesce(VMA.[Protein Collection List], '') AS protein_collection_list,
                   Coalesce(VMA.[Protein Options], '') AS protein_options,
                   Coalesce(VMA.Comment, '') AS comment,
                   Coalesce(VMA.State, '') AS state,
                   Coalesce(DPJ.Package_Comment, '') AS package_comment
            FROM S_V_Data_Package_Analysis_Jobs_Export AS DPJ
                 INNER JOIN V_Mage_Analysis_Jobs AS VMA  ON VMA.Job = DPJ.Job
            WHERE DPJ.Data_Package_ID = @DataPackageID
            ) job
        FOR XML AUTO, TYPE
        )
        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @jobXML), '')

        SET @result = @result + @crlf + '</jobs>' + @crlf
    END --<b>

    ---------------------------------------------------
    -- Job archive paths
    ---------------------------------------------------

    If @includeAll > 0 Or CHARINDEX('Paths', @options) > 0
    BEGIN --<c>

        SET @result = @result + @crlf + '<paths>'

        ---------------------------------------------------
        -- Data package path
        ---------------------------------------------------

        DECLARE @dpPathXML XML
        SET @dpPathXML = (
            SELECT REPLACE(Storage_Path_Relative, '\', '/') AS storage_path
            FROM S_V_Data_Package_Export AS data_package_path
            WHERE ID = @DataPackageID
            FOR XML AUTO, TYPE
        )
        SET @result = @result + @crlf
        SET @result = @result + '<!-- Copy this folder and its contents -->' + @crlf
        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @dpPathXML), '')

        ---------------------------------------------------
        -- Dataset paths
        ---------------------------------------------------

        DECLARE @dsPathXML XML
        SET @dsPathXML = (
        SELECT * FROM (
            SELECT DS.dataset_id,
                   ISNULL(AP.AP_archive_path, '') + '/' +
                   ISNULL(DS.DS_folder_name, DS.Dataset_Num) AS folder_path
            FROM S_V_Data_Package_Datasets_Export AS TDPD
                 INNER JOIN T_Dataset AS DS ON DS.Dataset_ID = TDPD.Dataset_ID
                 INNER JOIN T_Dataset_Archive AS DA ON DA.AS_Dataset_ID = DS.Dataset_ID
                 INNER JOIN T_Archive_Path AS AP ON AP.AP_path_ID = DA.AS_storage_path_ID
            WHERE TDPD.Data_Package_ID = @DataPackageID
            ) dataset_path
        FOR XML AUTO, TYPE
        )
        SET @result = @result + @crlf + @crlf
        SET @result = @result + '<!-- Copy each dataset folder and its file contents -->' + @crlf
        SET @result = @result + '<!-- (do not copy any subfolders). -->' + @crlf
        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @dsPathXML), '')

        ---------------------------------------------------
        -- Job paths
        ---------------------------------------------------

        DECLARE @jobPathXML XML
        SET @jobPathXML = (
        SELECT * FROM (
            SELECT -- DPJ.data_package_id,
                   DPJ.job,
                   -- DPJ.tool,
                   ISNULL(AP.AP_archive_path, '') + '/' +
                   ISNULL(TDS.DS_folder_name, TDS.Dataset_Num) + '/' +
                   ISNULL(AJ.AJ_resultsFolderName, '') AS folder_path
            FROM S_V_Data_Package_Analysis_Jobs_Export AS DPJ
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
        SET @result = @result + Coalesce(CONVERT(VARCHAR(MAX), @jobPathXML), '')

        SET @result = @result + @crlf + '</paths>' + @crlf
    END --<c>

    SET @result = @result + @crlf + '</data_package>'

    RETURN @result
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_data_package_xml] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_data_package_xml] TO [DMS2_SP_User] AS [dbo]
GO
