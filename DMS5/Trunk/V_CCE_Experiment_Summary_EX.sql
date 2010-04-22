/****** Object:  View [dbo].[V_CCE_Experiment_Summary_EX] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_CCE_Experiment_Summary_EX
AS
SELECT     TOP 100 PERCENT dbo.T_Cell_Culture.CC_Name AS [Cell Culture], dbo.T_Cell_Culture.CC_Reason AS [CC Reason], 
                      dbo.T_Cell_Culture.CC_Comment AS [CC Comment], GP.Value AS [Harvest Growth Phase], SC.Value AS [Stress Description], 
                      dbo.T_Experiments.Experiment_Num AS Experiment, dbo.T_Experiments.EX_reason AS [Exp Reason], 
                      dbo.T_Experiments.EX_comment AS [Exp Comment], dbo.T_Campaign.Campaign_Num AS Campaign, dbo.T_Organisms.OG_name AS Organism
FROM         dbo.T_Cell_Culture INNER JOIN
                      dbo.T_Experiment_Cell_Cultures ON dbo.T_Cell_Culture.CC_ID = dbo.T_Experiment_Cell_Cultures.CC_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Experiment_Cell_Cultures.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Experiments.EX_campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID LEFT OUTER JOIN
                          (SELECT     Target_ID, Value
                            FROM          V_AuxInfo_Value
                            WHERE      (Subcategory = 'Sample Culture Growth Conditions') AND (Item = 'Harvest Growth Phase')) GP ON 
                      dbo.T_Cell_Culture.CC_ID = GP.Target_ID LEFT OUTER JOIN
                          (SELECT     Target_ID, Value
                            FROM          V_AuxInfo_Value
                            WHERE      (Subcategory = 'Sample Culture Growth Conditions') AND (Item = 'Stress Description')) SC ON 
                      dbo.T_Cell_Culture.CC_ID = SC.Target_ID
ORDER BY dbo.T_Campaign.Campaign_Num, dbo.T_Experiments.Experiment_Num, dbo.T_Cell_Culture.CC_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_CCE_Experiment_Summary_EX] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_CCE_Experiment_Summary_EX] TO [PNL\D3M580] AS [dbo]
GO
