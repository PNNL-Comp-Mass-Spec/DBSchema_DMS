/****** Object:  View [dbo].[V_Ontology_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Ontology_List_Report]
AS
SELECT ontology_short_name AS ontology,
       identifier,
       term_name,
       is_leaf,
       definition,
       namespace,
       is_obsolete,
       is_root_term,
       term_pk
FROM V_Term

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ontology_List_Report] TO [DDL_Viewer] AS [dbo]
GO
