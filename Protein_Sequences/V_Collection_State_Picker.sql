/****** Object:  View [dbo].[V_Collection_State_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Collection_State_Picker]
AS
SELECT PCO.Protein_Collection_ID AS ID,
       PCO.Collection_Name AS Name,
       PCO.Organism_Name,
       PCS.State,
       PC.DateCreated AS Created,
       PC.DateModified AS Modified
FROM dbo.T_Protein_Collections PC
     INNER JOIN dbo.V_Protein_Collections_By_Organism PCO
                INNER JOIN dbo.T_Protein_Collection_States PCS
                  ON PCO.Collection_State_ID = PCS.Collection_State_ID
                INNER JOIN dbo.T_Protein_Collection_Types
                  ON PCO.Collection_Type_ID = dbo.T_Protein_Collection_Types.Collection_Type_ID
       ON PC.Protein_Collection_ID = PCO.Protein_Collection_ID


GO
