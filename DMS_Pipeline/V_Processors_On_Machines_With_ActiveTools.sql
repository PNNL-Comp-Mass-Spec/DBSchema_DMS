/****** Object:  View [dbo].[V_Processors_On_Machines_With_ActiveTools] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processors_On_Machines_With_ActiveTools]
AS
SELECT ST.Processor_Name,
       ST.Tool_Name,
       ST.Priority,
       ST.Enabled,
       ST.[Comment],
       ST.Latest_Request,
       ST.Proc_ID,
       ST.Processor_State,
       ST.Machine,
       ST.Total_CPUs,
       ST.Group_ID,
       ST.Group_Name,
       ST.Group_Enabled,
       Count(DISTINCT Cast(BusyProcessorsQ.Job AS varchar(12)) + 
                      Cast(BusyProcessorsQ.Step AS varchar(9))) ActiveTools,
	  Min(BusyProcessorsQ.Start) AS Start_Min,
	  Max(BusyProcessorsQ.Start) AS Start_Max,
	  Max(RunTime_Predicted_Hours) AS RunTime_Predicted_Hours_Max
FROM V_Processor_Step_Tools_List_Report ST
     INNER JOIN ( SELECT Machine,
                         Tool,
                         Job,
                         Step,
						 Start,
						 RunTime_Predicted_Hours
                  FROM V_Job_Steps2
                  WHERE (State = 4) ) BusyProcessorsQ
       ON ST.Machine = BusyProcessorsQ.Machine AND
          ST.Tool_Name = BusyProcessorsQ.Tool
GROUP BY ST.Processor_Name, ST.Tool_Name, ST.Priority, ST.Enabled, ST.[Comment], 
         ST.Latest_Request, ST.Proc_ID, ST.Processor_State, ST.Machine, ST.Total_CPUs, 
		 ST.Group_ID, ST.Group_Name, ST.Group_Enabled


GO
GRANT VIEW DEFINITION ON [dbo].[V_Processors_On_Machines_With_ActiveTools] TO [DDL_Viewer] AS [dbo]
GO
