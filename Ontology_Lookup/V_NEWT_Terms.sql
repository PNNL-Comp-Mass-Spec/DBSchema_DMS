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
       Parent_term_name,
       Parent_term_Identifier,
       Grandparent_term_name,
       Grandparent_term_identifier
FROM V_Term_Lineage
WHERE Ontology = 'NEWT' AND
      is_obsolete = 0 AND
      identifier LIKE '[0-9]%'


GO
GRANT VIEW DEFINITION ON [dbo].[V_NEWT_Terms] TO [DDL_Viewer] AS [dbo]
GO
