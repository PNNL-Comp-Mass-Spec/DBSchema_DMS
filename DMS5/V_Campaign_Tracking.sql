/****** Object:  View [dbo].[V_Campaign_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Campaign_Tracking
AS
SELECT     dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Campaign_Tracking.Cell_Culture_Count AS [Cell Cultures], 
                      dbo.T_Campaign_Tracking.Experiment_Count AS Experiments, dbo.T_Campaign_Tracking.Dataset_Count AS Datasets, 
                      dbo.T_Campaign_Tracking.Job_Count AS Jobs, dbo.T_Campaign.CM_comment AS Comment, dbo.T_Campaign.CM_created AS Created
FROM         dbo.T_Campaign_Tracking INNER JOIN
                      dbo.T_Campaign ON dbo.T_Campaign_Tracking.C_ID = dbo.T_Campaign.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Tracking] TO [PNL\D3M578] AS [dbo]
GO
