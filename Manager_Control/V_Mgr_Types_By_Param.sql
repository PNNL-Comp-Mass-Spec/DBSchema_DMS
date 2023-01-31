/****** Object:  View [dbo].[V_Mgr_Types_By_Param] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mgr_Types_By_Param]
AS
SELECT DISTINCT PT.ParamName As param_name,
                MT.MT_TypeName As mgr_type_name
FROM T_MgrType_ParamType_Map MP
     INNER JOIN T_MgrTypes MT
       ON MP.MgrTypeID = MT.MT_TypeID
     INNER JOIN T_ParamType PT
       ON MP.ParamTypeID = PT.ParamID


GO
