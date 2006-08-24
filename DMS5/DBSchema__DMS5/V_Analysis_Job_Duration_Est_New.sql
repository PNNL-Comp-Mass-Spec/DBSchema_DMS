/****** Object:  View [dbo].[V_Analysis_Job_Duration_Est_New] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Analysis_Job_Duration_Est_New
as
SELECT TOP 100 PERCENT   
	V_Analysis_Job.JobNum AS Job, T_Analysis_State_Name.AJS_name AS State, 
	V_Analysis_Job_Duration_Stats_Ex.[Avg Duration] AS [Avg Duration (min.)], V_Analysis_Job_Duration_Stats_Ex.[Std Dev (%)], 
	V_Analysis_Job_Duration_Stats_Ex.[Min Duration], V_Analysis_Job_Duration_Stats_Ex.[Max Duration], V_Analysis_Job.DatasetNum AS Dataset, 
	V_Analysis_Job.ToolName AS Tool, V_Analysis_Job.ParmFileName AS [Parm File], V_Analysis_Job.OrganismDBName AS [Organism DB File], 
	V_Analysis_Job.priority AS Priority, T_DatasetArchiveStateName.DASN_StateName AS ArchiveState, V_Analysis_Job.AssignedProcessor, 
	dbo.DatasetPreference(V_Analysis_Job.DatasetNum) AS Preference
FROM         
	V_Analysis_Job INNER JOIN
	T_Analysis_State_Name ON V_Analysis_Job.StateID = T_Analysis_State_Name.AJS_stateID INNER JOIN
	T_Dataset_Archive ON V_Analysis_Job.DatasetID = T_Dataset_Archive.AS_Dataset_ID INNER JOIN
	T_DatasetArchiveStateName ON T_Dataset_Archive.AS_state_ID = T_DatasetArchiveStateName.DASN_StateID LEFT OUTER JOIN
	V_Analysis_Job_Duration_Stats_Ex ON V_Analysis_Job.ToolName = V_Analysis_Job_Duration_Stats_Ex.Tool AND 
	V_Analysis_Job.OrganismDBName = V_Analysis_Job_Duration_Stats_Ex.OrganismDB AND 
	V_Analysis_Job.ParmFileName = V_Analysis_Job_Duration_Stats_Ex.[Parm File]
WHERE     
	(V_Analysis_Job.StateID = 1) OR
	(V_Analysis_Job.StateID = 2)
ORDER BY 
	dbo.DatasetPreference(V_Analysis_Job.DatasetNum) DESC, 
	V_Analysis_Job.AssignedProcessor DESC,
	Job

GO
