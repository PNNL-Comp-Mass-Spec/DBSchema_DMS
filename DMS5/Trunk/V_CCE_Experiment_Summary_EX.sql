/****** Object:  View [dbo].[V_CCE_Experiment_Summary_EX] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_CCE_Experiment_Summary_EX
AS
SELECT  top 100 percent   
T_Cell_Culture.CC_Name AS [Cell Culture],
T_Cell_Culture.CC_Reason AS [CC Reason],
T_Cell_Culture.CC_Comment AS [CC Comment],
GP.Value AS [Harvest Growth Phase],
SC.Value AS [Stress Description],
T_Experiments.Experiment_Num AS Experiment,
T_Experiments.EX_reason AS [Exp Reason],
T_Experiments.EX_comment AS [Exp Comment],
T_Campaign.Campaign_Num AS Campaign,
T_Experiments.EX_organism_name AS Organism
FROM T_Cell_Culture INNER JOIN
    T_Experiment_Cell_Cultures ON T_Cell_Culture.CC_ID = T_Experiment_Cell_Cultures.CC_ID INNER JOIN
    T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID INNER JOIN
    T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID LEFT OUTER JOIN
        (SELECT     Target_ID, Value
        FROM          V_AuxInfo_Value
        WHERE      (Subcategory = 'Sample Culture Growth Conditions') AND (Item = 'Harvest Growth Phase')) GP ON 
    T_Cell_Culture.CC_ID = GP.Target_ID LEFT OUTER JOIN
        (SELECT     Target_ID, Value
        FROM          V_AuxInfo_Value
        WHERE      (Subcategory = 'Sample Culture Growth Conditions') AND (Item = 'Stress Description')) SC ON 
    T_Cell_Culture.CC_ID = SC.Target_ID
ORDER BY T_Campaign.Campaign_Num, T_Experiments.Experiment_Num, T_Cell_Culture.CC_Name


GO
