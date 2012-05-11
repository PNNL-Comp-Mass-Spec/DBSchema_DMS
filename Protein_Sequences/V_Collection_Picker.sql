/****** Object:  View [dbo].[V_Collection_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Collection_Picker
AS
SELECT     PCByOrg.FileName AS Name, PCByOrg.Protein_Collection_ID AS ID, PCByOrg.Description, PCByOrg.NumProteins AS Entries, 
                      PCByOrg.Organism_Name, PCTypes.Type, AOF.Filesize, PCByOrg.Organism_ID
FROM         dbo.V_Protein_Collections_By_Organism AS PCByOrg INNER JOIN
                      dbo.T_Protein_Collection_Types AS PCTypes ON PCByOrg.Collection_Type_ID = PCTypes.Collection_Type_ID LEFT OUTER JOIN
                      dbo.T_Archived_Output_Files AS AOF ON PCByOrg.Authentication_Hash = AOF.Authentication_Hash
WHERE     (PCByOrg.Collection_State_ID BETWEEN 1 AND 3)

GO
