/****** Object:  View [dbo].[V_Protein_Collection_Members_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Protein_Collection_Members_List_Report]
AS
SELECT protein_collection_id,
       protein_collection,
       protein_name,
       description,
       reference_id,
       residue_count,
       monoisotopic_mass,
       protein_id
FROM S_V_Protein_Collection_Member_Names


GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Members_List_Report] TO [DDL_Viewer] AS [dbo]
GO
