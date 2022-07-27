/****** Object:  View [dbo].[V_Protein_Collections_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collections_Detail_Report]
AS
SELECT PC.Protein_Collection_ID AS [Collection ID],
       PC.Collection_Name AS Name,
       PC.Description,
       PC.NumProteins AS [Protein Count],
       PC.NumResidues AS [Residue Count],
       PC.DateCreated AS Created,
       PC.DateModified AS [Last Modified],
       dbo.T_Protein_Collection_Types.Type,
       PCS.State,
       PC.Authentication_Hash AS [CRC32 Fingerprint],
       NameAuth.Name AS [Original Naming Authority]
FROM dbo.T_Annotation_Types AnType
     INNER JOIN dbo.T_Naming_Authorities NameAuth
       ON AnType.Authority_ID = NameAuth.Authority_ID
     INNER JOIN dbo.T_Protein_Collections PC
                INNER JOIN dbo.T_Protein_Collection_States PCS
                  ON PC.Collection_State_ID 
                     = PCS.Collection_State_ID
                INNER JOIN dbo.T_Protein_Collection_Types
                  ON PC.Collection_Type_ID 
                     = dbo.T_Protein_Collection_Types.Collection_Type_ID
       ON AnType.Annotation_Type_ID 
          = PC.Primary_Annotation_Type_ID

GO
