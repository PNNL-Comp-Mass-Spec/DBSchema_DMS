/****** Object:  View [dbo].[V_Lab_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Lab_Locations]
AS
SELECT Lab_Name, Lab_Description, Sort_Weight
FROM T_Lab_Locations
WHERE Lab_Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Lab_Locations] TO [DDL_Viewer] AS [dbo]
GO
