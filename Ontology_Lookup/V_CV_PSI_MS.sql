/****** Object:  View [dbo].[V_CV_PSI_MS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_CV_PSI_MS]
AS
SELECT Entry_ID,
       Term_Name,
       identifier,
       Is_Leaf,
       Parent_term_name,
       Parent_term_ID,
       Grandparent_term_name,
       Grandparent_term_ID
FROM T_CV_MS


GO
GRANT VIEW DEFINITION ON [dbo].[V_CV_PSI_MS] TO [DDL_Viewer] AS [dbo]
GO
