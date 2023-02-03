/****** Object:  View [dbo].[V_Term_Hierarchy_PSI_MS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Term_Hierarchy_PSI_MS]
AS
-- This view uses a recursive query
-- It is elegant, but not efficient since the "T_Term" and "T_Term_Relationship" tables are so large
-- Use view V_CV_PSI_MS instead
WITH TermHierarchy
AS (
    SELECT Child.namespace,
           Child.term_name,
           Child.identifier,
           Child.term_pk,
           Child.is_obsolete,
           Child.is_leaf,
           CAST (null AS varchar(1000)) AS parent_name,
           CAST (null AS varchar(255)) AS parent_identifier,        
           CAST (NULL AS varchar(255)) AS parent_pk,                
           0 AS level
    FROM T_Term Child
    WHERE (Child.is_root_term = 1) AND
          (Child.namespace = 'MS')        -- Note that namespace 'MS' supersedes namespace 'PSI-MS'

    UNION ALL

    SELECT Child.namespace,
           Child.term_name,
           Child.identifier,
           Child.term_pk,
           Child.is_obsolete,
           Child.is_leaf,
           TermHierarchy.term_name AS parent_name,
           TermHierarchy.identifier AS parent_identifier,
           T_Term_Relationship.object_term_pk AS parent_pk,
           TermHierarchy.Level + 1 AS level
    FROM T_Term Child
         INNER JOIN T_Term_Relationship
           ON Child.term_pk = T_Term_Relationship.subject_term_pk
         INNER JOIN TermHierarchy on T_Term_Relationship.object_term_pk = TermHierarchy.term_pk
    WHERE (Child.namespace = 'MS')        -- Note that namespace 'MS' supersedes namespace 'PSI-MS'

)
SELECT *
FROM TermHierarchy


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term_Hierarchy_PSI_MS] TO [DDL_Viewer] AS [dbo]
GO
