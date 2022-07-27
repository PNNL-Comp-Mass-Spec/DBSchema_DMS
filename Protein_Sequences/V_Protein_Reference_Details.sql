/****** Object:  View [dbo].[V_Protein_Reference_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Reference_Details]
AS
SELECT PN.Name,
       PN.Description,
       NameAuth.Name AS [Authority Name],
       AnType.TypeName AS [Annotation Type],
       PC.Collection_Name AS [Originating Collection],
       PN.Protein_ID,
       PC.Protein_Collection_ID
FROM dbo.T_Annotation_Types AnType
     INNER JOIN dbo.T_Naming_Authorities NameAuth
       ON AnType.Authority_ID = NameAuth.Authority_ID
     INNER JOIN dbo.T_Protein_Names PN
       ON AnType.Annotation_Type_ID = PN.Annotation_Type_ID
     INNER JOIN dbo.T_Protein_Collection_Members PCM
       ON PN.Reference_ID = PCM.Original_Reference_ID
     INNER JOIN dbo.T_Protein_Collections PC
       ON PCM.Protein_Collection_ID = PC.Protein_Collection_ID


GO
