/****** Object:  View [dbo].[V_Ontology_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Ontology_List_Report]
AS
	SELECT Source,
		   Term_Name,
		   identifier,
		   Is_Leaf,
		   Parent_term_name,
		   Parent_term_ID,
		   GrandParent_term_name,
		   GrandParent_term_ID,
		   Term_PK
	FROM V_CV_Union



GO
GRANT VIEW DEFINITION ON [dbo].[V_Ontology_List_Report] TO [DDL_Viewer] AS [dbo]
GO
