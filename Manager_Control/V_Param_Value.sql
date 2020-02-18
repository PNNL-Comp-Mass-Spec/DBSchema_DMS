/****** Object:  View [dbo].[V_Param_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_Value]
AS
SELECT M.M_Name as Mgr_Name,
       PT.ParamName As Param_Name,
       PV.Entry_ID,
       PV.TypeID As Type_ID,
       PV.Value,
       PV.MgrID As Mgr_ID,
       PV.Comment,
       PV.Last_Affected,
       PV.Entered_By,
       M.M_TypeID As Mgr_Type_ID
FROM T_ParamValue PV
     INNER JOIN T_Mgrs M
       ON PV.MgrID = M.M_ID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID


GO
