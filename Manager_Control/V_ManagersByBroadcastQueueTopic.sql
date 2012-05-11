/****** Object:  View [dbo].[V_ManagersByBroadcastQueueTopic] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_ManagersByBroadcastQueueTopic
AS
SELECT     dbo.T_Mgrs.M_Name AS MgrName, dbo.T_MgrTypes.MT_TypeName AS MgrType, TB.BroadcastQueueTopic AS BroadcastTopic, 
                      TM.MessageQueueURI AS MsgQueueURI
FROM         dbo.T_Mgrs INNER JOIN
                          (SELECT     MgrID, Value AS BroadcastQueueTopic
                            FROM          dbo.T_ParamValue
                            WHERE      (TypeID = 117)) AS TB ON dbo.T_Mgrs.M_ID = TB.MgrID INNER JOIN
                      dbo.T_MgrTypes ON dbo.T_Mgrs.M_TypeID = dbo.T_MgrTypes.MT_TypeID INNER JOIN
                          (SELECT     MgrID, CONVERT(VARCHAR(128), Value) AS MessageQueueURI
                            FROM          dbo.T_ParamValue AS T_ParamValue_1
                            WHERE      (TypeID = 105)) AS TM ON dbo.T_Mgrs.M_ID = TM.MgrID

GO
