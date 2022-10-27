/****** Object:  View [dbo].[V_Analysis_Job_Processor_Group_Association_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Processor_Group_Association_List_Report]
AS
SELECT dbo.T_Analysis_Job_Processor_Group_Associations.Job_ID
     AS Job, dbo.T_Analysis_State_Name.AJS_name AS State,
    dbo.T_Dataset.Dataset_Num AS Dataset,
    dbo.T_Analysis_Tool.AJT_toolName AS Tool,
    dbo.T_Analysis_Job.AJ_parmFileName AS [Param File],
    dbo.T_Analysis_Job.AJ_settingsFileName AS [Settings File],
    dbo.T_Analysis_Job_Processor_Group_Associations.Group_ID AS
     #group_id
FROM dbo.T_Analysis_Job_Processor_Group_Associations INNER JOIN
    dbo.T_Analysis_Job ON
    dbo.T_Analysis_Job_Processor_Group_Associations.Job_ID = dbo.T_Analysis_Job.AJ_jobID
     INNER JOIN
    dbo.T_Dataset ON
    dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER
     JOIN
    dbo.T_Analysis_Tool ON
    dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID
     INNER JOIN
    dbo.T_Analysis_State_Name ON
    dbo.T_Analysis_Job.AJ_StateID = dbo.T_Analysis_State_Name.AJS_stateID
WHERE (dbo.T_Analysis_Job.AJ_StateID IN (1, 2, 3, 8, 9, 10, 11, 16,
    17))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processor_Group_Association_List_Report] TO [DDL_Viewer] AS [dbo]
GO
