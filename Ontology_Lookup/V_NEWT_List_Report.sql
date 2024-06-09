/****** Object:  View [dbo].[V_NEWT_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_NEWT_List_Report]
AS
SELECT term_name,
       identifier,
       is_leaf,
       parent_term_name,
       parent_term_id,
       grandparent_term_name,
       grandparent_term_id,
       rank,
       common_name,
       synonym,
       mnemonic,
       term_pk
FROM T_CV_NEWT

GO
GRANT VIEW DEFINITION ON [dbo].[V_NEWT_List_Report] TO [DDL_Viewer] AS [dbo]
GO
