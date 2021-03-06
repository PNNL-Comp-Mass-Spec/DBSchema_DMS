/****** Object:  View [dbo].[V_BTO_Tissue_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_BTO_Tissue_Report]
AS
SELECT Term_Name AS Tissue,
       Identifier AS Identifier,
       Is_Leaf AS [Is Leaf],
       Parent_term_name AS [Parent Tissue],
       Parent_term_ID AS [Parent ID],
       GrandParent_term_name AS [Grandparent Tissue],
       GrandParent_term_ID AS [Grandparent ID],
       [Synonyms] AS [Synonyms],
       Children AS Children,
       Usage_Last_12_Months [Usage],
       Usage_All_Time As [Usage (all time)],
       Entry_ID
FROM T_CV_BTO BTO


GO
