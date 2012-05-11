/****** Object:  View [dbo].[V_Tmp_Sorting_Index_Check] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Tmp_Sorting_Index_Check
AS
SELECT     Protein_Collection_ID, COUNT(Protein_Collection_ID) AS Count
FROM         dbo.T_Protein_Collection_Members
WHERE     (Sorting_Index IS NULL)
GROUP BY Protein_Collection_ID

GO
