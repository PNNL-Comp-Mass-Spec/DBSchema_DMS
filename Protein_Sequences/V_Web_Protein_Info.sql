/****** Object:  View [dbo].[V_Web_Protein_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Web_Protein_Info
AS
SELECT     Length, Monoisotopic_Mass AS [Monoisotopic mass], Average_Mass AS [Average mass], Molecular_Formula AS [Molecular formula], Sequence, 
                      CONVERT(varchar, DateModified, 101) AS [Last modified], CONVERT(varchar, DateCreated, 101) AS [Date entered], Protein_ID, 
                      SHA1_Hash AS [Authentication hash (SHA-1)], SEGUID
FROM         dbo.T_Proteins

GO
