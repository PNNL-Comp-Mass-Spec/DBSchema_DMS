/****** Object:  View [dbo].[V_Term_Lineage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Term_Lineage]
AS
SELECT Child.term_pk,
       Child.term_name,
       Child.identifier,
       Parent.term_name AS parent_term_name,
       Parent.identifier AS parent_term_identifier,
       Grandparent.term_name AS grandparent_term_name,                
       Grandparent.identifier AS grandparent_term_identifier,         
       Child.is_leaf,
       Child.is_obsolete,
       Child.[namespace],
       Child.ontology_id,
       O.shortName AS ontology,
       ParentChildRelationship.predicate_term_pk,
       Parent.term_pk AS parent_term_pk,
       Grandparent.term_pk AS grandparent_term_pk
FROM T_Ontology O
     INNER JOIN T_Term Child
       ON O.ontology_id = Child.ontology_id
     LEFT OUTER JOIN T_Term Grandparent
                     INNER JOIN T_Term_Relationship Grandparent_Parent_Relationship
                       ON Grandparent.term_pk = Grandparent_Parent_Relationship.object_term_pk
                     RIGHT OUTER JOIN T_Term Parent
                                      INNER JOIN T_Term_Relationship ParentChildRelationship
                                        ON Parent.term_pk = ParentChildRelationship.object_term_pk
                       ON Grandparent_Parent_Relationship.subject_term_pk = Parent.term_pk
       ON Child.term_pk = ParentChildRelationship.subject_term_pk


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term_Lineage] TO [DDL_Viewer] AS [dbo]
GO
