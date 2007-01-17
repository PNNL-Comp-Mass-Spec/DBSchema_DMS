/****** Object:  View [dbo].[V_Analysis_Dataset_Organism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Dataset_Organism
AS
SELECT     dbo.T_Dataset.Dataset_Num, dbo.T_Organisms.OG_name AS Organism, dbo.T_Organisms.OG_organismDBPath AS ClientPath, 
                      dbo.T_Organisms.OG_organismDBLocalPath AS ServerPath
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_Organisms ON dbo.T_Experiments.Ex_organism_ID = dbo.T_Organisms.Organism_ID

GO
