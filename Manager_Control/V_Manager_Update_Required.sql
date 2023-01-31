/****** Object:  View [dbo].[V_Manager_Update_Required] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_Update_Required]
AS
SELECT M.M_Name As mgr_name,
       PT.ParamName As param_name,
       PV.value
FROM T_Mgrs As M
     INNER JOIN T_ParamValue PV
       ON M.M_ID = PV.MgrID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID
WHERE PT.ParamName = 'ManagerUpdateRequired'


GO
