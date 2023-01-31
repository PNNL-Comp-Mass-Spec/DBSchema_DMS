/****** Object:  View [dbo].[V_Mgr_Params_By_Mgr_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mgr_Params_By_Mgr_Type]
AS
SELECT MT.MT_TypeName AS mgr_type,
       PT.ParamName AS param_name
FROM T_ParamType PT
     INNER JOIN T_MgrType_ParamType_Map MTPM
       ON PT.ParamID = MTPM.ParamTypeID
     INNER JOIN T_MgrTypes MT
       ON MTPM.MgrTypeID = MT.MT_TypeID


GO
