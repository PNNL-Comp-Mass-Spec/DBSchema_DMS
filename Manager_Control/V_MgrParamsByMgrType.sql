/****** Object:  View [dbo].[V_MgrParamsByMgrType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MgrParamsByMgrType]
AS
SELECT MT.MT_TypeName AS MgrType,
       PT.ParamName AS ParamName
FROM T_ParamType PT
     INNER JOIN T_MgrType_ParamType_Map MTPM
       ON PT.ParamID = MTPM.ParamTypeID
     INNER JOIN T_MgrTypes MT
       ON MTPM.MgrTypeID = MT.MT_TypeID

GO
