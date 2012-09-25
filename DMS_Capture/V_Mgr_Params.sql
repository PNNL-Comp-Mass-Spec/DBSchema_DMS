/****** Object:  View [dbo].[V_Mgr_Params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Mgr_Params
AS
SELECT ManagerID,
   ManagerName,
   ManagerType,
   ParameterName,
   ParameterValue,
   [Comment]
FROM S_Mgr_Params

GO
