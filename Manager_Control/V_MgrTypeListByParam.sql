/****** Object:  View [dbo].[V_MgrTypeListByParam] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MgrTypeListByParam]
AS
SELECT DISTINCT PT.ParamName, dbo.GetMgrTypeListByParamName(PT.ParamName) AS MgrTypeList
FROM   T_MgrType_ParamType_Map MP
       JOIN T_MgrTypes MT ON MP.MgrTypeID = MT.MT_TypeID 
       JOIN T_ParamType PT ON MP.ParamTypeID = PT.ParamID 


GO
