/****** Object:  View [dbo].[V_Internal_Standards_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Internal_Standards_Picklist
AS
SELECT Name AS val, '' AS ex
FROM dbo.T_Internal_Standards
WHERE (Internal_Std_Mix_ID > 0)

GO
