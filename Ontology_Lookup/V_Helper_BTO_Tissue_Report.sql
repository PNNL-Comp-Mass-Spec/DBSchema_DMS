/****** Object:  View [dbo].[V_Helper_BTO_Tissue_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_BTO_Tissue_Report]
AS
SELECT Term_Name AS Tissue,
       Identifier,
       Is_Leaf AS [Is Leaf],
       Parent_term_name AS [Parent Tissue],
       Parent_term_ID AS [Parent ID],
       Grandparent_term_name AS [Grandparent Tissue],
       Grandparent_term_ID AS [Grandparent ID],
       Synonyms AS Synonyms,
       Usage_Last_12_Months As Usage,
       Usage_All_Time As [Usage (all time],
       Entry_ID
FROM T_CV_BTO


GO
