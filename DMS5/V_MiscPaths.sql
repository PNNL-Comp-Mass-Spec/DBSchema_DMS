/****** Object:  View [dbo].[V_MiscPaths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MiscPaths]
AS
SELECT [Function], Client, [Server]
FROM T_MiscPaths


GO
GRANT VIEW DEFINITION ON [dbo].[V_MiscPaths] TO [PNL\D3M578] AS [dbo]
GO
