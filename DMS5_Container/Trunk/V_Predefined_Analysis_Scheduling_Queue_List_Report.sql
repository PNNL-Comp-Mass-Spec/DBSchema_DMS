/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] as
SELECT Item,
       Dataset_Num AS Dataset,
       Dataset_ID AS ID,
       CallingUser AS [User],
       State,
       Result_Code,
       Message,
       Entered,
       Last_Affected,
       Jobs_Created,
       AnalysisToolNameFilter AS [Analysis Tool Filter],
       ExcludeDatasetsNotReleased AS [Exclude Dataset Not Released],
       PreventDuplicateJobs AS [Prevent Duplicate Jobs]
FROM T_Predefined_Analysis_Scheduling_Queue


GO
