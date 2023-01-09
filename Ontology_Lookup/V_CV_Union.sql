/****** Object:  View [dbo].[V_CV_Union] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_CV_Union]
AS
    SELECT 'BTO' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_BTO
    UNION
    SELECT 'ENVO' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_ENVO
    UNION
    SELECT 'CL' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_CL
    UNION
    SELECT 'GO' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_GO
    UNION
    SELECT 'PSI-MI' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_MI
    UNION
    SELECT 'PSI-Mod' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_MOD
    UNION
    SELECT 'PSI-MS' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_MS
    UNION
    SELECT 'NEWT' AS source,
           term_pk,
           term_name,
           Cast(identifier as varchar(24)) AS identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_NEWT
    UNION
    SELECT 'PRIDE' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_PRIDE
    UNION
    SELECT 'DOID' AS source,
           term_pk,
           term_name,
           identifier,
           is_leaf,
           parent_term_name,
           parent_term_id,
           grandparent_term_name,
           grandparent_term_id
    FROM T_CV_DOID


GO
GRANT VIEW DEFINITION ON [dbo].[V_CV_Union] TO [DDL_Viewer] AS [dbo]
GO
