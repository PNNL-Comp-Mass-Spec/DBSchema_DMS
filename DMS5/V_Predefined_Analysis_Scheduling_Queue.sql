/****** Object:  View [dbo].[V_Predefined_Analysis_Scheduling_Queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Predefined_Analysis_Scheduling_Queue
AS
SELECT SQ.Item, SQ.Dataset_ID, DS.Dataset_Num AS Dataset, SQ.CallingUser, SQ.AnalysisToolNameFilter, 
   SQ.ExcludeDatasetsNotReleased, SQ.PreventDuplicateJobs, SQ.State, SQ.Result_Code, SQ.Message, SQ.Jobs_Created, 
   SQ.Entered, SQ.Last_Affected, COUNT(AJ.Job) AS Jobs, MIN(AJ.Tool) AS Tool_First, MAX(AJ.Tool) AS Tool_Last, 
   MIN(AJ.Started) AS Started_First, MAX(AJ.Started) AS Started_Last, SUM(AJ.Runtime) AS Total_Runtime
FROM T_Predefined_Analysis_Scheduling_Queue SQ LEFT OUTER JOIN
   V_Analysis_Job AJ INNER JOIN
   T_Dataset DS ON AJ.Dataset_ID = DS.Dataset_ID ON SQ.Dataset_ID = DS.Dataset_ID
GROUP BY SQ.Item, SQ.Dataset_ID, DS.Dataset_Num, SQ.CallingUser, SQ.AnalysisToolNameFilter, 
   SQ.ExcludeDatasetsNotReleased, SQ.PreventDuplicateJobs, SQ.State, SQ.Result_Code, SQ.Message, SQ.Jobs_Created, 
   SQ.Entered, SQ.Last_Affected

GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Scheduling_Queue] TO [DDL_Viewer] AS [dbo]
GO
