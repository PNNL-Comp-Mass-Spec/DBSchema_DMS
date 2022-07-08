/****** Object:  View [dbo].[V_Export_Biomaterial_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Export_Biomaterial_Experiments
AS
SELECT CC.CC_Name AS Biomaterial,
       E.Experiment_Num AS Experiment
FROM dbo.T_Cell_Culture CC
     INNER JOIN dbo.T_Experiment_Cell_Cultures ECC
       ON CC.CC_ID = ECC.CC_ID
     INNER JOIN dbo.t_experiments E
       ON ECC.Exp_ID = E.Exp_ID
;

GO
