/****** Object:  View [dbo].[V_Mgr_Params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Mgr_Params
AS
SELECT Manager_ID,
   Manager_Name,
   Manager_Type,
   Parameter_Name,
   Parameter_Value,
   [Comment],
   ManagerName,
   ParameterName,
   ParameterValue
FROM S_Mgr_Params


GO
GRANT VIEW DEFINITION ON [dbo].[V_Mgr_Params] TO [DDL_Viewer] AS [dbo]
GO
