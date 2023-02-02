/****** Object:  View [dbo].[V_Analysis_Mgr_Params_Update_Required] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Mgr_Params_Update_Required]
AS
SELECT PV.MgrID As mgr_id,
       M.M_Name As manager,
       PT.ParamName As param_name,
       PV.TypeID AS param_type_id,
       PV.value,
       PV.last_affected,
       PV.entered_by
FROM dbo.T_ParamValue AS PV
     INNER JOIN dbo.T_ParamType AS PT
       ON PV.TypeID = PT.ParamID
     INNER JOIN dbo.T_Mgrs AS M
       ON PV.MgrID = M.M_ID
WHERE PT.ParamName IN ('ManagerUpdateRequired') AND
      M.M_TypeID IN (11, 15)


GO
