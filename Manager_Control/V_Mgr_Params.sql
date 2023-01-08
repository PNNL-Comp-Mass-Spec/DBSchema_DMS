/****** Object:  View [dbo].[V_Mgr_Params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mgr_Params]
AS
SELECT PV.MgrID AS manager_id,
       M.M_Name AS manager_name,
       MT.MT_TypeName AS manager_type,
       PT.ParamName AS parameter_name,
       PV.Value AS parameter_value,
       PV.comment,
       PV.entry_id,
       PV.last_affected,
       PV.entered_by,
       -- The following are old column names, included for compatibility with older versions of the DMS managers
       M.M_Name AS ManagerName,
       PT.ParamName AS ParameterName,
       PV.Value AS ParameterValue
FROM T_Mgrs M
     INNER JOIN T_MgrTypes MT
       ON M.M_TypeID = MT.MT_TypeID
     INNER JOIN T_ParamValue PV
       ON M.M_ID = PV.MgrID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID


GO
