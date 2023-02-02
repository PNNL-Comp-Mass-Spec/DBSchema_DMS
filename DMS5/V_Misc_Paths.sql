/****** Object:  View [dbo].[V_Misc_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Misc_Paths]
AS
SELECT [function],
       client,
       [server],
       [comment]
FROM T_MiscPaths


GO
GRANT VIEW DEFINITION ON [dbo].[V_Misc_Paths] TO [DDL_Viewer] AS [dbo]
GO
