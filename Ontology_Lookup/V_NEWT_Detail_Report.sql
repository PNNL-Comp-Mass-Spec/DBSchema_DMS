/****** Object:  View [dbo].[V_NEWT_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_NEWT_Detail_Report]
AS
SELECT N.term_name,
       N.identifier,
       N.parent_term_name,
       N.parent_term_id AS parent_term_identifier,
       N.grandparent_term_name,
       N.grandparent_term_id AS grandparent_term_identifier,
       N.is_leaf,
       N.rank,
       N.common_name,
       N.synonym,
       N.mnemonic,
       N.term_pk,
       Parent.term_pk AS parent_term_pk,
       Grandparent.term_pk AS grandparent_term_pk
FROM T_CV_NEWT N
     LEFT OUTER JOIN T_CV_NEWT Parent
       ON N.Parent_Term_ID = Parent.Identifier
     LEFT OUTER JOIN T_CV_NEWT Grandparent
       ON N.Grandparent_Term_ID = Grandparent.Identifier

GO
GRANT VIEW DEFINITION ON [dbo].[V_NEWT_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
