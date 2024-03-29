/****** Object:  UserDefinedFunction [dbo].[check_data_package_dataset_job_coverage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[check_data_package_dataset_job_coverage]
/****************************************************
**
**  Desc:
**      Returns a table of dataset job coverage
**
**  Auth:   grk
**  Date:   05/22/2010
**          04/25/2018 mem - Now joining T_Data_Package_Datasets and T_Data_Package_Analysis_Jobs on Dataset_ID
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in data package item tables
**          09/26/2023 mem - Obtain dataset names from T_Dataset
**          09/28/2023 mem - Obtain tool names from T_Analysis_Tool
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

    -- Package datasets with no package jobs for tool
    --
    IF @mode = 'NoPackageJobs'
    BEGIN
        INSERT INTO @table_variable ( Dataset, Num )
        SELECT DS.Dataset_Num AS Dataset,
               NULL AS job_count
        FROM T_Data_Package_Datasets AS DPD
             INNER JOIN S_Dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
             LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS DPJ
                             INNER JOIN S_analysis_job AJ
                               ON AJ.AJ_JobID = DPJ.Job
                             INNER JOIN S_analysis_tool T
                               ON AJ.AJ_AnalysisToolID = T.AJT_ToolID AND
                                  T.AJT_ToolName = @tool
               ON DPD.Dataset_ID = DPJ.Dataset_ID AND
                  DPD.Data_Pkg_ID = DPJ.Data_Pkg_ID
        WHERE DPD.Data_Pkg_ID = @packageID AND
              DPJ.job Is Null;
    END

    -- Package datasets with no DMS jobs for tool
    --
    IF @mode = 'NoDMSJobs'
    BEGIN
        INSERT INTO @table_variable ( Dataset, Num )
        SELECT DS.Dataset_Num AS Dataset,
               NULL AS job_count
        FROM T_Data_Package_Datasets AS DPD
             INNER JOIN S_Dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
        WHERE DPD.Data_Pkg_ID = @packageID AND
              NOT EXISTS ( SELECT J.Dataset_ID
                           FROM S_V_Analysis_Job_List_Report_2 AS J
                           WHERE J.Tool = @tool AND
                                 J.Dataset_ID = DPD.Dataset_ID
                         );
    END

    -- For each dataset, return the number of jobs for the given tool in the data package
    --
    IF @mode = 'PackageJobCount'
    BEGIN
        INSERT INTO @table_variable ( Dataset, Num )
        SELECT DS.Dataset_Num AS Dataset,
               SUM(CASE WHEN DPJ.Job IS NULL THEN 0 ELSE 1 END) AS job_count
        FROM T_Data_Package_Datasets AS DPD
             INNER JOIN S_Dataset DS
               ON DPD.Dataset_ID = DS.Dataset_ID
             LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS DPJ
                             INNER JOIN S_analysis_job AJ
                               ON AJ.AJ_JobID = DPJ.Job
                             INNER JOIN S_analysis_tool T
                               ON AJ.AJ_AnalysisToolID = T.AJT_ToolID AND
                                  T.AJT_ToolName = @tool
               ON DPD.Dataset_ID = DPJ.Dataset_ID AND
                  DPD.Data_Pkg_ID = DPJ.Data_Pkg_ID
        WHERE DPD.Data_Pkg_ID = @packageID
        GROUP BY DS.Dataset_Num;
    END

    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[check_data_package_dataset_job_coverage] TO [DDL_Viewer] AS [dbo]
GO
