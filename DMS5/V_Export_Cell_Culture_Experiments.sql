/****** Object:  View [dbo].[V_Export_Cell_Culture_Experiments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
                       
CREATE VIEW [dbo].[V_Export_Cell_Culture_Experiments]
AS
SELECT CC.CC_Name AS CellCulture,
       E.Experiment_Num AS Experiment
FROM T_Cell_Culture CC
     INNER JOIN T_Experiment_Cell_Cultures ECC
       ON CC.CC_ID = ECC.CC_ID
     INNER JOIN T_Experiments E
       ON ECC.Exp_ID = E.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Export_Cell_Culture_Experiments] TO [DDL_Viewer] AS [dbo]
GO
