/****** Object:  View [dbo].[V_Mgr_Params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Mgr_Params]
AS
SELECT PV.MgrID AS ManagerID,
       M.M_Name AS ManagerName,
       MT.MT_TypeName AS ManagerType,
       PT.ParamName AS ParameterName,
       PV.Value AS ParameterValue,
       PV.Comment,
       PV.Entry_ID,
       PV.Last_Affected,
       PV.Entered_By
FROM T_Mgrs M
     INNER JOIN T_MgrTypes MT
       ON M.M_TypeID = MT.MT_TypeID
     INNER JOIN T_ParamValue PV
       ON M.M_ID = PV.MgrID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID


GO
