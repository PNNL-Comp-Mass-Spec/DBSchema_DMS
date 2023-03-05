/****** Object:  View [dbo].[V_Statistics_Entities_By_Year] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Statistics_Entities_By_Year]
AS
SELECT PivotData.YEAR AS year,
       IsNull([New_Research_Campaigns], 0) AS new_research_campaigns,
       IsNull([New_Organisms], 0) AS new_organisms,
       IsNull([Prepared_samples], 0) AS prepared_samples,
       IsNull([Requested_instrument_runs], 0) AS requested_instrument_runs,
       IsNull([Datasets], 0) AS datasets,
       IsNull([Analysis_Jobs], 0) AS analysis_jobs,
       IsNull([Data_Packages], 0) AS data_packages,
       IsNull([Analysis_Job_Step_Tool_Started], 0) AS analysis_job_step_tool_started,
       IsNull([Capture_Task_Step_Tool_Started], 0) AS capture_task_step_tool_started
FROM (SELECT YEAR(AJ_start) AS Year,
             'Analysis Jobs' AS Item,
             COUNT(*) AS Items
      FROM T_Analysis_Job INNER JOIN
           T_Analysis_Tool
             ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID
      WHERE (NOT (AJ_start IS NULL)) AND
            (T_Analysis_Tool.AJT_toolName <> 'MSClusterDAT_Gen')
      GROUP BY YEAR(AJ_start)
      UNION
      SELECT YEAR(DS_created) AS Year,
             'Datasets' AS Item,
             COUNT(*) AS Items
      FROM T_Dataset
      WHERE DS_type_ID <> 100   -- Exclude tracking datasets
      GROUP BY YEAR(DS_created)
      UNION
      SELECT YEAR(EX_created) AS Year,
             'Prepared samples' AS Item,
             COUNT(*) AS Items
      FROM T_Experiments
      GROUP BY YEAR(EX_created)
      UNION
      SELECT YEAR(RDS_created) AS Year,
             'Requested instrument runs' AS Item,
             COUNT(*) AS Items
      FROM T_Requested_Run
      GROUP BY YEAR(RDS_created)
      UNION
      SELECT YEAR(OG_created) AS Year,
             'New Organisms' AS Item,
             COUNT(*) AS Items
      FROM T_Organisms
      GROUP BY YEAR(OG_created)
      UNION
      SELECT YEAR(CM_Created) AS Year,
             'New Research Campaigns' AS Item,
             COUNT(*) AS Items
      FROM T_Campaign
      GROUP BY YEAR(CM_Created)
      UNION
      SELECT YEAR(Created) AS Year,
             'Data Packages' AS Item,
             COUNT(*) AS Items
      FROM DMS_Data_Package.dbo.T_Data_Package
      GROUP BY YEAR(Created)
      UNION
      SELECT YEAR(Start) AS Year,
             'Analysis Job Step Tool Started' AS Item,
             COUNT(*) AS Items
      FROM DMS_Pipeline.dbo.T_Job_Steps_History
      WHERE (NOT (Start IS NULL))
      GROUP BY YEAR(Start)
      UNION
      SELECT YEAR(Start) AS Year,
             'Capture Task Step Tool Started' AS Item,
             COUNT(*) AS Items
      FROM DMS_Capture.dbo.T_Task_Steps_History
      WHERE (NOT (Start IS NULL))
      GROUP BY YEAR(Start)
     ) AS SourceTable
     PIVOT ( SUM(Items)
             FOR Item
             IN ( [Analysis_Jobs],
                  [Datasets],
                  [Prepared_samples],
                  [Requested_instrument_runs],
                  [New_Organisms],
                  [New_Research_Campaigns],
                  [Data_Packages],
                  [Analysis_Job_Step_Tool_Started],
                  [Capture_Task_Step_Tool_Started]
                 )
     ) AS PivotData

GO
GRANT VIEW DEFINITION ON [dbo].[V_Statistics_Entities_By_Year] TO [DDL_Viewer] AS [dbo]
GO
