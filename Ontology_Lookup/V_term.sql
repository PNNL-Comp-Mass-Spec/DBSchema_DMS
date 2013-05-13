/****** Object:  View [dbo].[V_Term] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_term]
AS
SELECT dbo.term.term_pk,
       dbo.term.ontology_id,
       dbo.ontology.shortName,
       dbo.term.term_name,
       dbo.term.identifier,
       dbo.term.definition,
       dbo.term.namespace,
       dbo.term.is_obsolete,
       dbo.term.is_root_term,
       dbo.term.is_leaf
FROM dbo.ontology
     INNER JOIN dbo.term
       ON dbo.ontology.ontology_id = dbo.term.ontology_id


GO
