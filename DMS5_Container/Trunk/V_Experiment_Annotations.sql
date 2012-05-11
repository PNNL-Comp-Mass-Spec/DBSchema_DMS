/****** Object:  View [dbo].[V_Experiment_Annotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Annotations
AS
SELECT E.Experiment_Num AS Experiment, 
    EA.Experiment_ID AS Exp_ID, EA.Key_Name, EA.Value
FROM dbo.T_Experiment_Annotations EA INNER JOIN
    dbo.T_Experiments E ON EA.Experiment_ID = E.Exp_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Annotations] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Annotations] TO [PNL\D3M580] AS [dbo]
GO
