/****** Object:  View [dbo].[V_Protein_Collections_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Protein_Collections_List_Report]
AS
SELECT PC.Protein_Collection_ID AS Collection_ID,
       PC.Collection_Name AS Name,
       PC.Description,
       PCS.State,
       PC.NumProteins AS Protein_Count,
       PC.NumResidues AS Residue_Count,
       NamingAuth.Name + ' - ' + AnType.TypeName AS Annotation_Type,
       PC.DateCreated AS Created,
       PC.DateModified AS Last_Modified
FROM T_Annotation_Types AnType
     INNER JOIN T_Naming_Authorities NamingAuth
       ON AnType.Authority_ID = NamingAuth.Authority_ID
     INNER JOIN T_Protein_Collections PC
                INNER JOIN T_Protein_Collection_States PCS
                  ON PC.Collection_State_ID = PCS.Collection_State_ID
       ON AnType.Annotation_Type_ID = PC.Primary_Annotation_Type_ID


GO
