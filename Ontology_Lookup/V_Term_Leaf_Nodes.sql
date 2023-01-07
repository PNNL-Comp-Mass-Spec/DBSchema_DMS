/****** Object:  View [dbo].[V_Term_Leaf_Nodes] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Term_Leaf_Nodes]
AS
SELECT *
FROM V_Term
WHERE is_leaf=1


GO
GRANT VIEW DEFINITION ON [dbo].[V_Term_Leaf_Nodes] TO [DDL_Viewer] AS [dbo]
GO
