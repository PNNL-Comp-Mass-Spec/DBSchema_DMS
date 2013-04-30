/****** Object:  View [dbo].[V_Term_Hierarchy_PSI_MS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Term_Hierarchy_PSI_MS
AS
	WITH TermHierarchy
	AS (
		SELECT Child.namespace,
			   Child.term_name,
			   Child.identifier,
			   Child.term_pk,
			   Child.is_obsolete,
			   Child.is_leaf,
			   CAST (null as varchar(1000)) AS Parent_Name,
			   CAST (null as varchar(255)) AS Parent_Identifier,
			   cast(NULL AS varchar(255)) AS parent_pk,
			   0 AS Level
		FROM term Child
		WHERE (Child.is_root_term = 1) AND
			  (Child.namespace = 'PSI-MS')
			   
		UNION ALL
		
		SELECT Child.namespace,
			   Child.term_name,
			   Child.identifier,
			   Child.term_pk,
			   Child.is_obsolete,
			   Child.is_leaf,
			   TermHierarchy.term_name AS Parent_Name,
			   TermHierarchy.identifier AS Parent_Identifier,
			   term_relationship.object_term_pk AS parent_pk,
			   TermHierarchy.Level + 1 AS Level
		FROM term Child
			 INNER JOIN term_relationship
			   ON Child.term_pk = term_relationship.subject_term_pk
			 INNER JOIN TermHierarchy on term_relationship.object_term_pk = TermHierarchy.term_pk
		WHERE (Child.namespace = 'PSI-MS')

	)
	SELECT *
	FROM TermHierarchy

GO
