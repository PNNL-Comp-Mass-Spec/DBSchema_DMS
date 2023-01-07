/****** Object:  View [dbo].[V_Term_Categories] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Term_Categories]
AS
SELECT T.term_pk,
       T.ontology_id,
       O.shortName As short_name,
       T.term_name,
       T.identifier,
       T.definition,
       T.namespace,
       T.is_obsolete,
       T.is_root_term,
       T.is_leaf
FROM T_Ontology O
     INNER JOIN T_Term T
       ON O.ontology_id = T.ontology_id
WHERE is_leaf=0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term_Categories] TO [DDL_Viewer] AS [dbo]
GO
