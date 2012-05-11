/****** Object:  View [dbo].[V_Collection_State_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Collection_State_Picker
AS
SELECT     TOP 100 PERCENT dbo.V_Protein_Collections_By_Organism.Protein_Collection_ID AS ID, 
                      dbo.V_Protein_Collections_By_Organism.FileName AS Name, dbo.V_Protein_Collections_By_Organism.Organism_Name, 
                      dbo.T_Protein_Collection_States.State, dbo.T_Protein_Collections.DateCreated AS Created, dbo.T_Protein_Collections.DateModified AS Modified
FROM         dbo.T_Protein_Collections INNER JOIN
                      dbo.V_Protein_Collections_By_Organism INNER JOIN
                      dbo.T_Protein_Collection_States ON 
                      dbo.V_Protein_Collections_By_Organism.Collection_State_ID = dbo.T_Protein_Collection_States.Collection_State_ID INNER JOIN
                      dbo.T_Protein_Collection_Types ON 
                      dbo.V_Protein_Collections_By_Organism.Collection_Type_ID = dbo.T_Protein_Collection_Types.Collection_Type_ID ON 
                      dbo.T_Protein_Collections.Protein_Collection_ID = dbo.V_Protein_Collections_By_Organism.Protein_Collection_ID
ORDER BY dbo.V_Protein_Collections_By_Organism.FileName

GO
