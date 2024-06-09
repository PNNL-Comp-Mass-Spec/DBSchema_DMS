/****** Object:  View [dbo].[V_Ontology_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Ontology_List_Report]
AS
SELECT source,
       term_name,
       identifier,
       is_leaf,
       parent_term_name,
       parent_term_id,
       grandparent_term_name,
       grandparent_term_id,
       term_pk
FROM V_CV_Union


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ontology_List_Report] TO [DDL_Viewer] AS [dbo]
GO
