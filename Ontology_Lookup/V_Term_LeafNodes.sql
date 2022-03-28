/****** Object:  View [dbo].[V_Term_LeafNodes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Term_LeafNodes]
AS
SELECT *
FROM V_Term
WHERE is_leaf=1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term_LeafNodes] TO [DDL_Viewer] AS [dbo]
GO
