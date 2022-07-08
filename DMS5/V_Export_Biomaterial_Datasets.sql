/****** Object:  View [dbo].[V_Export_Biomaterial_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Export_Biomaterial_Datasets
AS
SELECT DISTINCT CC.CC_Name AS Biomaterial,
        CC.CC_ID As Biomaterial_ID, 
        DS.Dataset_ID
FROM dbo.T_Cell_Culture CC INNER JOIN
     dbo.T_Experiment_Cell_Cultures ECC ON CC.CC_ID = ECC.CC_ID INNER JOIN
     dbo.t_experiments E ON ECC.Exp_ID = E.Exp_ID INNER JOIN
     dbo.t_dataset DS ON E.Exp_ID = DS.Exp_ID
;

GO
