/****** Object:  View [dbo].[x_Unused_V_DMS_PDB_Organism_XRef] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[x_Unused_V_DMS_PDB_Organism_XRef]
AS
SELECT     dbo.T_Organisms_Ext.Organism_ID, dbo.T_Organisms_Ext.Short_Name, dbo.T_Organisms_Ext.DMS_Name, 
                      DMS5.dbo.T_Organisms.Organism_ID AS DMS_Organism_ID, DMS5.dbo.T_Organisms.OG_name
FROM         dbo.T_Organisms_Ext FULL OUTER JOIN
                      DMS5.dbo.T_Organisms ON dbo.T_Organisms_Ext.DMS_Name = DMS5.dbo.T_Organisms.OG_name

GO
