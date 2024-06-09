/****** Object:  View [dbo].[V_NEWT_Terms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_NEWT_Terms]
AS
SELECT N.term_name,
       N.identifier,
       N.term_pk,
       N.is_leaf,
       N.rank,
       N.parent_term_name,
       N.parent_term_id as parent_term_identifier,
       N.grandparent_term_name,
       N.grandparent_term_id AS grandparent_term_identifier,
       N.common_name,
       N.synonym,
       N.mnemonic
FROM T_CV_NEWT N

GO
GRANT VIEW DEFINITION ON [dbo].[V_NEWT_Terms] TO [DDL_Viewer] AS [dbo]
GO
