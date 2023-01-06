/****** Object:  View [dbo].[V_BTO_Tissue_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_BTO_Tissue_Report]
AS
SELECT Term_Name AS tissue,
       Identifier AS identifier,
       Is_Leaf AS is_leaf,
       Parent_term_name AS parent_tissue,
       Parent_term_ID AS parent_id,
       Grandparent_term_name AS grandparent_tissue,
       Grandparent_term_ID AS grandparent_id,
       Synonyms AS synonyms,
       Children AS children,
       Usage_Last_12_Months As usage,
       Usage_All_Time AS usage_all_time,
       entry_id
FROM T_CV_BTO BTO


GO
