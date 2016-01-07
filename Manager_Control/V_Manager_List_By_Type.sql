/****** Object:  View [dbo].[V_Manager_List_By_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_List_By_Type]
AS
SELECT M.M_ID AS ID, M.M_Name AS [Manager Name], 
    MT.MT_TypeName AS [Manager Type], ISNULL(ActiveQ.Active, 
    'not defined') AS Active, M.M_TypeID, 
    ActiveQ.Last_Affected AS [State Last Changed], 
    ActiveQ.Entered_By AS [Changed By],
	M.M_Comment AS [Comment]
FROM dbo.T_Mgrs AS M INNER JOIN
    dbo.T_MgrTypes AS MT ON 
    M.M_TypeID = MT.MT_TypeID LEFT OUTER JOIN
        (SELECT PV.MgrID, PV.Value AS Active, PV.Last_Affected, 
           PV.Entered_By
      FROM dbo.T_ParamValue AS PV INNER JOIN
           dbo.T_ParamType AS PT ON 
           PV.TypeID = PT.ParamID
      WHERE (PT.ParamName = 'mgractive')) AS ActiveQ ON 
    M.M_ID = ActiveQ.MgrID
WHERE (M.M_ControlFromWebsite > 0)


GO
