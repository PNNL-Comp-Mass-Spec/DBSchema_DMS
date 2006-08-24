/****** Object:  View [dbo].[V_Analysis_Job_Duration_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create view V_Analysis_Job_Duration_Stats
as
SELECT     
T_Campaign.Campaign_Num AS Campaign, 
T_Analysis_Tool.AJT_toolName AS Tool, 
T_Analysis_Job.AJ_parmFileName AS [Parm File], 
T_Analysis_Job.AJ_organismDBName AS OrganismDB, 
COUNT(T_Analysis_Job.AJ_jobID) AS [Num. Jobs], 
MAX(V_Analysis_Job_Duration.Duration) AS [Max Duration], 
MIN(V_Analysis_Job_Duration.Duration) AS [Min Duration], 
AVG(V_Analysis_Job_Duration.Duration) AS [Avg Duration], 
ROUND(STDEV(V_Analysis_Job_Duration.Duration), 1) AS [Std Dev], 
ROUND(100 * STDEV(V_Analysis_Job_Duration.Duration) / AVG(V_Analysis_Job_Duration.Duration), 1) AS [Std Dev (%)]
FROM         T_Experiments INNER JOIN
                      T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID INNER JOIN
                      T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID INNER JOIN
                      T_Analysis_Job INNER JOIN
                      T_Analysis_Tool ON T_Analysis_Job.AJ_analysisToolID = T_Analysis_Tool.AJT_toolID ON 
                      T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID INNER JOIN
                      V_Analysis_Job_Duration ON T_Analysis_Job.AJ_jobID = V_Analysis_Job_Duration.Job
GROUP BY 
T_Analysis_Tool.AJT_toolName, 
T_Analysis_Job.AJ_parmFileName, 
T_Analysis_Job.AJ_organismDBName, 
T_Campaign.Campaign_Num


GO
