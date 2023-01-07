/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report]
AS
SELECT SQ.item,
       D.Dataset_Num AS dataset,
       SQ.Dataset_ID AS id,
       SQ.CallingUser AS [user],
       SQ.state,
       SQ.result_code,
       SQ.message,
       SQ.entered,
       SQ.last_affected,
       SQ.jobs_created,
       SQ.AnalysisToolNameFilter AS analysis_tool_filter,
       SQ.ExcludeDatasetsNotReleased AS exclude_dataset_not_released,
       SQ.PreventDuplicateJobs AS prevent_duplicate_jobs
FROM T_Predefined_Analysis_Scheduling_Queue SQ
     INNER JOIN T_Dataset D
       ON SQ.Dataset_ID = D.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] TO [DDL_Viewer] AS [dbo]
GO
