/****** Object:  View [dbo].[V_NEWT_Terms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_NEWT_Terms]
AS
SELECT term_name,
       identifier,
       term_pk,
       is_leaf,
       parent_term_name,
       parent_term_identifier,
       grandparent_term_name,
       grandparent_term_identifier
FROM V_Term_Lineage
WHERE ontology = 'NEWT' AND
      is_obsolete = 0 AND
      identifier LIKE '[0-9]%'


GO
GRANT VIEW DEFINITION ON [dbo].[V_NEWT_Terms] TO [DDL_Viewer] AS [dbo]
GO
