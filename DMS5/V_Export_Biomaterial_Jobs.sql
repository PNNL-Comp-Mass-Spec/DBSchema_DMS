/****** Object:  View [dbo].[V_Export_Biomaterial_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Export_Biomaterial_Jobs
AS
SELECT DISTINCT 
       CC.CC_Name AS Biomaterial,
       CC.CC_ID As Biomaterial_ID, 
       J.AJ_jobID as Job
FROM dbo.T_Cell_Culture CC INNER JOIN
     dbo.T_Experiment_Cell_Cultures ECC ON CC.CC_ID = ECC.CC_ID INNER JOIN
     dbo.t_experiments E ON ECC.Exp_ID = E.Exp_ID INNER JOIN
     dbo.t_dataset DS ON E.Exp_ID = DS.Exp_ID INNER JOIN
     dbo.t_analysis_job J ON DS.Dataset_ID = J.AJ_datasetID
;
GO
