/****** Object:  View [dbo].[V_Protein_Reference_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Reference_Details
AS
SELECT TOP 100 PERCENT dbo.T_Protein_Names.Name, 
    dbo.T_Protein_Names.Description, 
    dbo.T_Naming_Authorities.Name AS [Authority Name], 
    dbo.T_Annotation_Types.TypeName AS [Annotation Type], 
    dbo.T_Protein_Collections.FileName AS [Originating Collection], 
    dbo.T_Protein_Names.Protein_ID, 
    dbo.T_Protein_Collections.Protein_Collection_ID
FROM dbo.T_Annotation_Types INNER JOIN
    dbo.T_Naming_Authorities ON 
    dbo.T_Annotation_Types.Authority_ID = dbo.T_Naming_Authorities.Authority_ID
     INNER JOIN
    dbo.T_Protein_Names ON 
    dbo.T_Annotation_Types.Annotation_Type_ID = dbo.T_Protein_Names.Annotation_Type_ID
     INNER JOIN
    dbo.T_Protein_Collection_Members ON 
    dbo.T_Protein_Names.Reference_ID = dbo.T_Protein_Collection_Members.Original_Reference_ID
     INNER JOIN
    dbo.T_Protein_Collections ON 
    dbo.T_Protein_Collection_Members.Protein_Collection_ID = dbo.T_Protein_Collections.Protein_Collection_ID

GO
