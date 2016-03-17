/****** Object:  View [dbo].[V_Cell_Culture_Experiment_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Cell_Culture_Experiment_Tracking
AS
SELECT     T_Experiments.Experiment_Num AS Experiment, COUNT(T_Dataset.Dataset_ID) AS Datasets, T_Experiments.EX_reason AS Reason, 
                      T_Experiments.EX_created AS Created, T_Cell_Culture.CC_Name AS [#CCName]
FROM         T_Experiment_Cell_Cultures INNER JOIN
                      T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID INNER JOIN
                      T_Cell_Culture ON T_Experiment_Cell_Cultures.CC_ID = T_Cell_Culture.CC_ID LEFT OUTER JOIN
                      T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
GROUP BY T_Cell_Culture.CC_Name, T_Experiments.Experiment_Num, T_Experiments.EX_reason, T_Experiments.EX_created


GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Experiment_Tracking] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Experiment_Tracking] TO [PNL\D3M580] AS [dbo]
GO
