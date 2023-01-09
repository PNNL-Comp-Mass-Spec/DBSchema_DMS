/****** Object:  View [dbo].[V_Biomaterial_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_Tracking]
AS
SELECT dbo.T_Cell_Culture.CC_Name AS biomaterial_name,
       dbo.T_Cell_Culture_Tracking.Experiment_Count AS experiments,
       dbo.T_Cell_Culture_Tracking.Dataset_Count AS datasets,
       dbo.T_Cell_Culture_Tracking.Job_Count AS jobs,
       dbo.T_Cell_Culture.CC_Reason AS reason,
       dbo.T_Cell_Culture.CC_Created AS created
FROM dbo.T_Cell_Culture_Tracking
     INNER JOIN dbo.T_Cell_Culture
       ON dbo.T_Cell_Culture_Tracking.CC_ID = dbo.T_Cell_Culture.CC_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Tracking] TO [DDL_Viewer] AS [dbo]
GO
