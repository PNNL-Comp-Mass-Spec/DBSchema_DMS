/****** Object:  View [dbo].[V_Protein_Headers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Headers]
AS
SELECT T_Protein_Headers.Protein_ID,
       T_Protein_Names.Name AS Protein_Name,
       T_Protein_Collections.Protein_Collection_ID,
       T_Protein_Collections.Collection_Name AS Protein_Collection_Name,
       T_Protein_Headers.Sequence_Head
FROM T_Protein_Headers
     INNER JOIN T_Protein_Names
       ON T_Protein_Headers.Protein_ID = T_Protein_Names.Protein_ID
     INNER JOIN T_Protein_Collection_Members
       ON T_Protein_Names.Reference_ID = T_Protein_Collection_Members.Original_Reference_ID
     INNER JOIN T_Protein_Collections
       ON T_Protein_Collection_Members.Protein_Collection_ID 
          = T_Protein_Collections.Protein_Collection_ID

GO
