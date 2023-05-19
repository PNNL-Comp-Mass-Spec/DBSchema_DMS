/****** Object:  View [dbo].[V_Protein_Collection_Members_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Protein_Collection_Members_Detail_Report]
AS
SELECT 'Use V_Protein_Collection_Members_List_Report or use stored procedure get_protein_collection_member_detail' AS message,
       'When using S_V_Protein_Collection_Members, always use a Where clause' AS warning

GO
GRANT VIEW DEFINITION ON [dbo].[V_Protein_Collection_Members_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
