/****** Object:  View [dbo].[V_CV_PRIDE] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_CV_PRIDE]
AS
SELECT entry_id,
       term_name,
       identifier,
       is_leaf,
       parent_term_name,
       parent_term_id,
       grandparent_term_name,
       grandparent_term_id
FROM T_CV_PRIDE


GO
GRANT VIEW DEFINITION ON [dbo].[V_CV_PRIDE] TO [DDL_Viewer] AS [dbo]
GO
