/****** Object:  View [dbo].[V_Protein_Collection_Members_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Protein_Collection_Members_Detail_Report]
AS
SELECT 'Use V_Protein_Collection_Members_List_Report or use stored procedure GetProteinCollectionMemberDetail' AS Message,
       'When using S_V_Protein_Collection_Members, always use as Where clause' AS Warning


GO
