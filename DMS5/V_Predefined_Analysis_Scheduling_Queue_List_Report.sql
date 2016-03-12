/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] as
SELECT SQ.Item,
       D.Dataset_Num AS Dataset,
       SQ.Dataset_ID AS ID,
       SQ.CallingUser AS [User],
       SQ.State,
       SQ.Result_Code,
       SQ.Message,
       SQ.Entered,
       SQ.Last_Affected,
       SQ.Jobs_Created,
       SQ.AnalysisToolNameFilter AS [Analysis Tool Filter],
       SQ.ExcludeDatasetsNotReleased AS [Exclude Dataset Not Released],
       SQ.PreventDuplicateJobs AS [Prevent Duplicate Jobs]
FROM T_Predefined_Analysis_Scheduling_Queue SQ
     INNER JOIN T_Dataset D
       ON SQ.Dataset_ID = D.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Queue_List_Report] TO [PNL\D3M578] AS [dbo]
GO
