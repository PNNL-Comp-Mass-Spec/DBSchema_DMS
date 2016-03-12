/****** Object:  View [dbo].[V_Cell_Culture_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Cell_Culture_Tracking
AS
SELECT     dbo.T_Cell_Culture.CC_Name AS [Cell Culture], dbo.T_Cell_Culture_Tracking.Experiment_Count AS Experiments, 
                      dbo.T_Cell_Culture_Tracking.Dataset_Count AS Datasets, dbo.T_Cell_Culture_Tracking.Job_Count AS Jobs, dbo.T_Cell_Culture.CC_Reason AS Reason, 
                      dbo.T_Cell_Culture.CC_Created AS Created
FROM         dbo.T_Cell_Culture_Tracking INNER JOIN
                      dbo.T_Cell_Culture ON dbo.T_Cell_Culture_Tracking.CC_ID = dbo.T_Cell_Culture.CC_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Tracking] TO [PNL\D3M578] AS [dbo]
GO
