/****** Object:  View [dbo].[V_Analysis_Dataset_Organism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Dataset_Organism]
AS
SELECT DS.Dataset_Num,
       Org.OG_name AS Organism,
       Org.OG_organismDBPath AS ClientPath,
       '' AS ServerPath
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Experiments
       ON DS.Exp_ID = dbo.T_Experiments.Exp_ID
     INNER JOIN dbo.T_Organisms Org
       ON dbo.T_Experiments.Ex_organism_ID = Org.Organism_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Dataset_Organism] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Dataset_Organism] TO [PNL\D3M580] AS [dbo]
GO
