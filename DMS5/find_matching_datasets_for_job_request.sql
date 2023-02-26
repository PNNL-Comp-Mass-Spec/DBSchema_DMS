/****** Object:  StoredProcedure [dbo].[find_matching_datasets_for_job_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[find_matching_datasets_for_job_request]
/****************************************************
**
**  Desc:
**      Return list of datasets for given job request
**      showing how many jobs exist for each that
**      match the parameters of the request
**      (regardless of whether or not job is linked to request)
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   01/08/2008 grk - Initial release
**          02/11/2009 mem - Updated to allow for OrgDBName to not be 'na' when using protein collection lists
**          06/17/2009 mem - Updated to ignore OrganismName when using protein collection lists
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          06/09/2017 mem - Add support for state 13 (inactive)
**          06/30/2022 mem - Rename parameter file argument
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/25/2023 bcg - Update output table column names to lower-case
**
*****************************************************/
(
    @requestID int,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare
        @datasetList varchar(8000),
        @toolName varchar(64),
        @paramFileName varchar(255),
        @settingsFileName varchar(255),
        @organismDBName varchar(128),
        @organismName varchar(128),
        @proteinCollectionList varchar(512),
        @proteinOptionsList varchar(256)

        ---------------------------------------------------
        -- get job parameters and list of datasets from request
        ---------------------------------------------------
        --
        SELECT
            @datasetList = AJR_datasets,
            @toolName = AJR_analysisToolName,
            @paramFileName = AJR_parmFileName,
            @settingsFileName = AJR_settingsFileName,
            @organismName = OG_name,
            @organismDBName = AJR_organismDBName,
            @proteinCollectionList = AJR_proteinCollectionList,
            @proteinOptionsList = AJR_proteinOptionsList
        FROM
            T_Analysis_Job_Request INNER JOIN
            T_Organisms ON AJR_organism_ID = T_Organisms.Organism_ID
        WHERE
            AJR_requestID = @requestID

        ---------------------------------------------------
        -- get request datasets into local table
        ---------------------------------------------------
        --
        Declare @requestDatasets Table (
            dataset varchar(128)
        )
        --
        INSERT INTO @requestDatasets(dataset)
        SELECT Item FROM dbo.make_table_from_list(@datasetList)

        ---------------------------------------------------
        -- get list of datasets that have jobs that match
        -- job parameters from request
        ---------------------------------------------------
        --
        Declare @matchingJobDatasets Table (
            dataset varchar(128),
            jobs int,
            new int,
            busy int,
            complete int,
            failed int,
            holding int
        )
        --
        INSERT INTO @matchingJobDatasets(dataset, jobs, new, busy, complete, failed, holding)
        SELECT
            DS.Dataset_Num AS dataset,
            COUNT(*) as jobs,
            SUM(CASE WHEN AJ.AJ_StateID IN (1) THEN 1 ELSE 0 END) AS new,
            SUM(CASE WHEN AJ.AJ_StateID IN (2, 3, 9, 10, 11, 16, 17) THEN 1 ELSE 0 END) AS busy,
            SUM(CASE WHEN AJ.AJ_StateID IN (4, 14) THEN 1 ELSE 0 END) AS complete,
            SUM(CASE WHEN AJ.AJ_StateID IN (5, 6, 7, 12, 13, 15, 18, 99) THEN 1 ELSE 0 END) AS failed,
            SUM(CASE WHEN AJ.AJ_StateID IN (8) THEN 1 ELSE 0 END) AS holding
        FROM
            T_Dataset DS INNER JOIN
            T_Analysis_Job AJ ON AJ.AJ_datasetID = DS.Dataset_ID INNER JOIN
            T_Analysis_Tool AJT ON AJ.AJ_analysisToolID = AJT.AJT_toolID INNER JOIN
            T_Organisms Org ON AJ.AJ_organismID = Org.Organism_ID  INNER JOIN
            T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID INNER JOIN
            @requestDatasets RD ON RD.dataset = DS.Dataset_Num
        WHERE
            AJT.AJT_toolName = @toolName AND
            AJ.AJ_parmFileName = @paramFileName AND
            AJ.AJ_settingsFileName = @settingsFileName AND
            ( (    @proteinCollectionList = 'na' AND AJ.AJ_organismDBName = @organismDBName AND
                Org.OG_name = Coalesce(@organismName, Org.OG_name)
              ) OR
              (    @proteinCollectionList <> 'na' AND
                AJ.AJ_proteinCollectionList = Coalesce(@proteinCollectionList, AJ.AJ_proteinCollectionList) AND
                AJ.AJ_proteinOptionsList = Coalesce(@proteinOptionsList, AJ.AJ_proteinOptionsList)
              )
            )
        GROUP BY DS.Dataset_Num

        ---------------------------------------------------
        -- output
        ---------------------------------------------------

        SELECT '' AS sel, dataset, jobs, new, busy, complete, failed, holding
        FROM @matchingJobDatasets
        UNION
        SELECT '' AS Sel, dataset AS dataset, 0 AS jobs, 0 AS new, 0 AS busy, 0 AS complete, 0 AS failed, 0 AS holding
        FROM @requestDatasets
        WHERE NOT dataset IN (SELECT dataset FROM @matchingJobDatasets)

GO
GRANT VIEW DEFINITION ON [dbo].[find_matching_datasets_for_job_request] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_matching_datasets_for_job_request] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_matching_datasets_for_job_request] TO [Limited_Table_Write] AS [dbo]
GO
