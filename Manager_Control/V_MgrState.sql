/****** Object:  View [dbo].[V_MgrState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_MgrState
AS
SELECT MS.MgrID, M.M_Name AS [Manager Name], MT.MT_TypeName AS [Manager Type], 
     MS.TypeID AS [Param Type], PT.ParamName AS [Param Name], MS.Value AS State
FROM T_MgrState MS
    JOIN T_Mgrs M ON M.M_ID = MS.MgrID
    JOIN T_MgrTypes MT ON MT.MT_TypeID = M.M_TypeID
	JOIN T_ParamType PT ON PT.ParamID = MS.TypeID

GO
GRANT INSERT ON [dbo].[V_MgrState] TO [DMSWebUser] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_MgrState] TO [DMSWebUser] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_MgrState] TO [DMSWebUser] AS [dbo]
GO
GRANT INSERT ON [dbo].[V_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT UPDATE ON [dbo].[V_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_MgrState] TO [Mgr_Config_Admin] AS [dbo]
GO
