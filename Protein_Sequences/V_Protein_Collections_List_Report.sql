/****** Object:  View [dbo].[V_Protein_Collections_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Collections_List_Report
AS
SELECT     dbo.T_Protein_Collections.Protein_Collection_ID AS [Collection ID], dbo.T_Protein_Collections.FileName AS Name, 
                      dbo.T_Protein_Collections.Description, dbo.T_Protein_Collection_States.State, dbo.T_Protein_Collections.NumProteins AS [Protein Count], 
                      dbo.T_Protein_Collections.NumResidues AS [Residue Count], 
                      dbo.T_Naming_Authorities.Name + ' - ' + dbo.T_Annotation_Types.TypeName AS [Annotation Type], dbo.T_Protein_Collections.DateCreated AS Created, 
                      dbo.T_Protein_Collections.DateModified AS [Last Modified]
FROM         dbo.T_Annotation_Types INNER JOIN
                      dbo.T_Naming_Authorities ON dbo.T_Annotation_Types.Authority_ID = dbo.T_Naming_Authorities.Authority_ID INNER JOIN
                      dbo.T_Protein_Collections INNER JOIN
                      dbo.T_Protein_Collection_States ON dbo.T_Protein_Collections.Collection_State_ID = dbo.T_Protein_Collection_States.Collection_State_ID ON 
                      dbo.T_Annotation_Types.Annotation_Type_ID = dbo.T_Protein_Collections.Primary_Annotation_Type_ID

GO
