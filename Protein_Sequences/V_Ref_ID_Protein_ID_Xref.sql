/****** Object:  View [dbo].[V_Ref_ID_Protein_ID_Xref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ref_ID_Protein_ID_Xref
AS
SELECT PCM.Original_Reference_ID AS ref_id,
       PN.Name AS name,
       PN.Description AS description,
       OrgInfo.Organism_Name AS organism,
       PCM.Protein_ID AS protein_id
FROM dbo.V_Organism_Picker orginfo
     INNER JOIN dbo.T_Collection_Organism_Xref OrgXref
       ON OrgInfo.ID = OrgXref.Organism_ID
     INNER JOIN dbo.T_Protein_Collection_Members PCM
                INNER JOIN dbo.T_Protein_Names PN
                  ON PCM.Original_Reference_ID = PN.Reference_ID
       ON OrgXref.Protein_Collection_ID = PCM.Protein_Collection_ID


GO
