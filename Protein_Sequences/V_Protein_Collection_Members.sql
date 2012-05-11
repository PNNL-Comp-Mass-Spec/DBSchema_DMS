/****** Object:  View [dbo].[V_Protein_Collection_Members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_Members]
AS

SELECT PN.Reference_ID,
       PN.Name,
       PN.Description,
       PN.Annotation_Type_ID,
       PCM.Protein_ID,
       PCM.Protein_Collection_ID,
       PCM.Original_Reference_ID
FROM T_Protein_Names PN
     INNER JOIN T_Proteins P
       ON PN.Protein_ID = P.Protein_ID
     INNER JOIN T_Protein_Collection_Members PCM
       ON P.Protein_ID = PCM.Protein_ID AND
          PN.Reference_ID = PCM.Original_Reference_ID


GO
