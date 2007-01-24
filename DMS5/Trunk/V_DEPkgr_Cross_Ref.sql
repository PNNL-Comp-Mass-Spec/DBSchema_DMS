/****** Object:  View [dbo].[V_DEPkgr_Cross_Ref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Cross_Ref
AS
SELECT     dbo.T_Analysis_Job.AJ_jobID AS AnalysisJob_ID, dbo.T_Dataset.Dataset_ID, dbo.T_Requested_Run_History.ID AS DatasetRequest_ID, 
                      dbo.T_Dataset.Dataset_Num AS Dataset_Name, dbo.T_Requested_Run_History.RDS_Name AS DatasetRequest_Name, 
                      dbo.T_Analysis_Tool.AJT_toolName AS Analysis_Tool_Name, dbo.T_Experiments.Experiment_Num AS Experiment_Name, 
                      dbo.T_Requested_Run_History.Exp_ID AS Experiment_ID, dbo.T_Analysis_Job.AJ_start AS Sorting_Date, 
                      dbo.T_Dataset.Acq_Time_Start AS Acquisition_Time, dbo.T_Dataset.DS_LC_column_ID AS LC_Column_ID, 
                      dbo.T_Cell_Culture.CC_Name AS CellCulture_Name, dbo.T_Campaign.Campaign_Num AS Campaign_Name
FROM         dbo.T_Analysis_Job INNER JOIN
                      dbo.T_Dataset ON dbo.T_Analysis_Job.AJ_datasetID = dbo.T_Dataset.Dataset_ID INNER JOIN
                      dbo.T_Requested_Run_History ON dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run_History.DatasetID INNER JOIN
                      dbo.T_Analysis_Tool ON dbo.T_Analysis_Job.AJ_analysisToolID = dbo.T_Analysis_Tool.AJT_toolID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID AND 
                      dbo.T_Requested_Run_History.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Experiment_Cell_Cultures ON dbo.T_Experiments.Exp_ID = dbo.T_Experiment_Cell_Cultures.Exp_ID INNER JOIN
                      dbo.T_Cell_Culture ON dbo.T_Experiment_Cell_Cultures.CC_ID = dbo.T_Cell_Culture.CC_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID

GO
