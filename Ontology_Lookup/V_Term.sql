/****** Object:  View [dbo].[V_Term] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Term]
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
       O.shortName AS Ontology_ShortName,
       O.fullName AS Ontology_FullName
FROM T_Ontology O
     INNER JOIN T_Term T
       ON O.ontology_id = T.ontology_id


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term] TO [DDL_Viewer] AS [dbo]
GO
