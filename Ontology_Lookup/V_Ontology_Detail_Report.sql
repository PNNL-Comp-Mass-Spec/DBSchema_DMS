/****** Object:  View [dbo].[V_Ontology_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Ontology_Detail_Report]
AS
SELECT T.term_pk,
       T.term_name,
       T.identifier,
       T.definition,
       T.namespace,
       T.is_obsolete,
       T.is_root_term,
       T.is_leaf,
       T.ontology_id,
       T.ontology_short_name,
       T.ontology_full_name,
       L.parent_term_name,
       L.parent_term_identifier,
       L.parent_term_pk,
       L.grandparent_term_name,
       L.grandparent_term_identifier,
       L.grandparent_term_pk,
       L.predicate_term_pk
FROM V_Term T
     INNER JOIN V_Term_Lineage L
       ON T.term_pk = L.term_pk


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ontology_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
