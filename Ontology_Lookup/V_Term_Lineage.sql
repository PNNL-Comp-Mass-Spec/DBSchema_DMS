/****** Object:  View [dbo].[V_Term_Lineage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Term_Lineage
AS
SELECT Child.[namespace],
       Grandparent.term_name AS Grandparent_term_name,
       Grandparent.identifier AS Grandparent_term_identifier,
       Parent.term_name AS Parent_term_name,
       Parent.identifier AS Parent_term_identifier,
       Child.term_name,
       Child.identifier,
       Child.is_leaf,
       ParentChildRelationship.predicate_term_pk,
       Grandparent.term_pk AS Grandparent_term_pk,
       Parent.term_pk AS Parent_term_pk,
       Child.term_pk
FROM term Grandparent
     INNER JOIN term_relationship GrandParent_Parent_Relationship
       ON Grandparent.term_pk = GrandParent_Parent_Relationship.object_term_pk
     RIGHT OUTER JOIN term Parent
                      INNER JOIN term_relationship ParentChildRelationship
                        ON Parent.term_pk = ParentChildRelationship.object_term_pk
       ON GrandParent_Parent_Relationship.subject_term_pk = Parent.term_pk
     RIGHT OUTER JOIN term Child
       ON ParentChildRelationship.subject_term_pk = Child.term_pk


GO
