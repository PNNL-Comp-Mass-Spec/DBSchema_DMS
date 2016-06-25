/****** Object:  View [dbo].[V_Protein_Collection_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Protein_Collection_Members_List_Report
AS
SELECT Protein_Collection_ID,
		Protein_Collection,
		Protein_Name,
		Description,
		Residue_Count,
		Monoisotopic_Mass,
		Protein_ID,
		Reference_ID
FROM S_V_Protein_Collection_Member_Names

GO
