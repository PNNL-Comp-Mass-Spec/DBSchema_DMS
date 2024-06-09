/****** Object:  View [dbo].[V_Helper_NEWT_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Helper_NEWT_List_Report]
AS
SELECT identifier,
       term_name,
       parent_term_name AS parent,
       grandparent_term_name AS grandparent,
       common_name,
       is_leaf,
       rank
FROM V_CV_NEWT

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_NEWT_List_Report] TO [DDL_Viewer] AS [dbo]
GO
