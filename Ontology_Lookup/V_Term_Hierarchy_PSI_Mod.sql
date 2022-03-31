/****** Object:  View [dbo].[V_Term_Hierarchy_PSI_Mod] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Term_Hierarchy_PSI_Mod]
AS
-- This view uses a recursive query
-- It is elegant, but not efficient since the "T_Term" and "T_Term_Relationship" tables are so large
-- Use view V_CV_PSI_Mod instead
WITH TermHierarchy
AS (
    SELECT Child.namespace,
           Child.term_name,
           Child.identifier,
           Child.term_pk,
           Child.is_obsolete,
           Child.is_leaf,
           CAST (null AS varchar(1000)) AS Parent_Name,
           CAST (null AS varchar(255)) AS Parent_Identifier,
           CAST (NULL AS varchar(255)) AS parent_pk,
           0 AS Level
    FROM T_Term Child
    WHERE (Child.is_root_term = 1) AND
          (Child.namespace = 'PSI-MOD')

    UNION ALL

    SELECT Child.namespace,
           Child.term_name,
           Child.identifier,
           Child.term_pk,
           Child.is_obsolete,
           Child.is_leaf,
           TermHierarchy.term_name AS Parent_Name,
           TermHierarchy.identifier AS Parent_Identifier,
           T_Term_Relationship.object_term_pk AS parent_pk,
           TermHierarchy.Level + 1 AS Level
    FROM T_Term Child
         INNER JOIN T_Term_Relationship
           ON Child.term_pk = T_Term_Relationship.subject_term_pk
         INNER JOIN TermHierarchy on T_Term_Relationship.object_term_pk = TermHierarchy.term_pk
    WHERE (Child.namespace = 'PSI-MOD')

)
SELECT *
FROM TermHierarchy


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term_Hierarchy_PSI_Mod] TO [DDL_Viewer] AS [dbo]
GO
