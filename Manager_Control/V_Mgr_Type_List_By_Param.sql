/****** Object:  View [dbo].[V_Mgr_Type_List_By_Param] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Mgr_Type_List_By_Param]
AS
SELECT DISTINCT PT.ParamName As param_name,
                dbo.get_mgr_type_list_by_param_name(PT.ParamName) AS mgr_type_list
FROM T_MgrType_ParamType_Map MP
     INNER JOIN T_MgrTypes MT
       ON MP.MgrTypeID = MT.MT_TypeID
     INNER JOIN T_ParamType PT
       ON MP.ParamTypeID = PT.ParamID

GO
