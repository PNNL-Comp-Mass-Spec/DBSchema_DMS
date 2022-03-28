/****** Object:  View [dbo].[V_Term] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Term]
AS
SELECT dbo.term.term_pk,
       dbo.term.term_name,
       dbo.term.identifier,
       dbo.term.definition,
       dbo.term.namespace,
       dbo.term.is_obsolete,
       dbo.term.is_root_term,
       dbo.term.is_leaf,
       dbo.term.ontology_id,
       dbo.ontology.shortName AS Ontology_ShortName,
       dbo.ontology.fullName AS Ontology_FullName
FROM dbo.ontology
     INNER JOIN dbo.term
       ON dbo.ontology.ontology_id = dbo.term.ontology_id


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term] TO [DDL_Viewer] AS [dbo]
GO
