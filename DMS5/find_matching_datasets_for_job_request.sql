/****** Object:  StoredProcedure [dbo].[FindMatchingDatasetsForJobRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FindMatchingDatasetsForJobRequest]
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
        insert into @requestDatasets(dataset)
        select Item from dbo.MakeTableFromList(@datasetList)

        ---------------------------------------------------
        -- get list of datasets that have jobs that match
        -- job parameters from request
        ---------------------------------------------------
        --
        Declare @matchingJobDatasets Table (
            Dataset varchar(128),
            Jobs int,
            New int,
            Busy int,
            Complete int,
            Failed int,
            Holding int
        )
        --
        INSERT INTO @matchingJobDatasets(Dataset, Jobs, New, Busy, Complete, Failed, Holding)
        SELECT
            DS.Dataset_Num AS Dataset,
            COUNT(*) as Jobs,
            SUM(CASE WHEN AJ.AJ_StateID IN (1) THEN 1 ELSE 0 END) AS New,
            SUM(CASE WHEN AJ.AJ_StateID IN (2, 3, 9, 10, 11, 16, 17) THEN 1 ELSE 0 END) AS Busy,
            SUM(CASE WHEN AJ.AJ_StateID IN (4, 14) THEN 1 ELSE 0 END) AS Complete,
            SUM(CASE WHEN AJ.AJ_StateID IN (5, 6, 7, 12, 13, 15, 18, 99) THEN 1 ELSE 0 END) AS Failed,
            SUM(CASE WHEN AJ.AJ_StateID IN (8) THEN 1 ELSE 0 END) AS Holding
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

        select '' as Sel, Dataset, Jobs, New, Busy, Complete, Failed, Holding
        from @matchingJobDatasets
        union
        select '' as Sel, dataset as Dataset, 0 as Jobs, 0 as New, 0 as Busy, 0 as Complete, 0 as Failed, 0 as Holding
        from @requestDatasets
        where not dataset in (select dataset from @matchingJobDatasets)

GO
GRANT VIEW DEFINITION ON [dbo].[FindMatchingDatasetsForJobRequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[FindMatchingDatasetsForJobRequest] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[FindMatchingDatasetsForJobRequest] TO [Limited_Table_Write] AS [dbo]
GO
