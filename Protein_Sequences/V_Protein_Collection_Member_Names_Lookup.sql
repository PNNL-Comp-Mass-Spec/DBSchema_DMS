/****** Object:  View [dbo].[V_Protein_Collection_Member_Names_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Protein_Collection_Member_Names_Lookup
AS
SELECT     dbo.T_Protein_Names.Name AS name, dbo.T_Protein_Collection_Members.Protein_Collection_ID AS collection_id
FROM         dbo.T_Protein_Names INNER JOIN
                      dbo.T_Protein_Collection_Members ON dbo.T_Protein_Names.Reference_ID = dbo.T_Protein_Collection_Members.Original_Reference_ID

GO
