/****** Object:  View [dbo].[V_Analysis_Tool_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Analysis_Tool_Picklist
AS
SELECT AJT_toolID AS ID, AJT_toolName As Name 
FROM T_Analysis_Tool 
WHERE AJT_active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Tool_Picklist] TO [DDL_Viewer] AS [dbo]
GO
