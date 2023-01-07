/****** Object:  View [dbo].[V_Manager_List_By_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_List_By_Type]
AS
SELECT M.M_ID AS id,
       M.M_Name AS manager_name,
       MT.MT_TypeName AS manager_type,
       ISNULL(ActiveQ.active, 'not defined') AS active,
       M.M_TypeID As mgr_type_id,
       ActiveQ.Last_Affected AS state_last_changed,
       ActiveQ.Entered_By AS changed_by,
       M.M_Comment AS comment
FROM dbo.T_Mgrs AS M
     INNER JOIN dbo.T_MgrTypes AS MT
       ON M.M_TypeID = MT.MT_TypeID
     LEFT OUTER JOIN ( SELECT PV.MgrID,
                              PV.VALUE AS Active,
                              PV.Last_Affected,
                              PV.Entered_By
                       FROM dbo.T_ParamValue AS PV
                            INNER JOIN dbo.T_ParamType AS PT
                              ON PV.TypeID = PT.ParamID
                       WHERE (PT.ParamName = 'mgractive') ) AS ActiveQ
       ON M.M_ID = ActiveQ.MgrID
WHERE (M.M_ControlFromWebsite > 0)


GO
