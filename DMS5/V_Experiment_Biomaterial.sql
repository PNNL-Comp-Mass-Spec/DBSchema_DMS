/****** Object:  View [dbo].[V_Experiment_Biomaterial] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Experiment_Biomaterial]
AS
SELECT E.Experiment_Num As Experiment,
       CC.CC_Name AS Biomaterial_Name
FROM T_Experiment_Cell_Cultures ECC
     INNER JOIN T_Experiments E
       ON ECC.Exp_ID = E.Exp_ID
     INNER JOIN T_Cell_Culture CC
       ON ECC.CC_ID = CC.CC_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Biomaterial] TO [DDL_Viewer] AS [dbo]
GO
