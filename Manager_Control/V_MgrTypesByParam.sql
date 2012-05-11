/****** Object:  View [dbo].[V_MgrTypesByParam] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MgrTypesByParam]
AS
SELECT DISTINCT PT.ParamName, MT.MT_TypeName
FROM   T_MgrType_ParamType_Map MP
       JOIN T_MgrTypes MT ON MP.MgrTypeID = MT.MT_TypeID 
       JOIN T_ParamType PT ON MP.ParamTypeID = PT.ParamID 

  
GO
