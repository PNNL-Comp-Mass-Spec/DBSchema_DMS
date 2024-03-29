/****** Object:  View [dbo].[V_Old_Param_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Old_Param_Value]
AS
SELECT M.M_Name As mgr_name,
       PT.ParamName As param_name,
       PV.entry_id,
       PV.TypeID As param_type_id,
       PV.value,
       PV.MgrID As mgr_id,
       PV.comment,
       PV.last_affected,
       PV.entered_by,
       M.M_TypeID As mgr_type_id
FROM T_ParamValue_OldManagers PV
     INNER JOIN T_OldManagers M
       ON PV.MgrID = M.M_ID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID


GO
