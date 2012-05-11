/****** Object:  View [dbo].[V_MgrParamsByMgrType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_MgrParamsByMgrType
AS
SELECT     TOP 100 PERCENT dbo.T_MgrTypes.MT_TypeName AS MgrType, dbo.T_ParamType.ParamName AS ParamName
FROM         dbo.T_ParamType INNER JOIN
                      dbo.T_MgrType_ParamType_Map ON dbo.T_ParamType.ParamID = dbo.T_MgrType_ParamType_Map.ParamTypeID INNER JOIN
                      dbo.T_MgrTypes ON dbo.T_MgrType_ParamType_Map.MgrTypeID = dbo.T_MgrTypes.MT_TypeID
ORDER BY dbo.T_MgrTypes.MT_TypeName

GO
