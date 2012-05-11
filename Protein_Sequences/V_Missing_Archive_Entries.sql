/****** Object:  View [dbo].[V_Missing_Archive_Entries] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Missing_Archive_Entries
AS
SELECT     Protein_Collection_ID, FileName, Authentication_Hash, DateModified, Collection_Type_ID, NumProteins
FROM         dbo.T_Protein_Collections
WHERE     (NOT (Authentication_Hash IN
                          (SELECT     Authentication_Hash
                            FROM          T_Archived_Output_Files)))

GO
