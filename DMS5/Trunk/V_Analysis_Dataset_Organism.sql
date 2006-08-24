/****** Object:  View [dbo].[V_Analysis_Dataset_Organism] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_Analysis_Dataset_Organism
AS
SELECT T_Dataset.Dataset_Num, 
   T_Experiments.EX_organism_name AS Organism, 
   T_Organisms.OG_organismDBPath AS ClientPath, 
   T_Organisms.OG_organismDBLocalPath AS ServerPath
FROM T_Dataset INNER JOIN
   T_Experiments ON 
   T_Dataset.Exp_ID = T_Experiments.Exp_ID INNER JOIN
   T_Organisms ON 
   T_Experiments.EX_organism_name = T_Organisms.OG_name
GO
