/****** Object:  View [dbo].[V_ManagersByBroadcastQueueTopic] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_ManagersByBroadcastQueueTopic]
AS
SELECT M.M_Name AS MgrName,
       MT.MT_TypeName AS MgrType,
       TB.BroadcastQueueTopic AS BroadcastTopic,
       TM.MessageQueueURI AS MsgQueueURI
FROM T_Mgrs M
     INNER JOIN ( SELECT MgrID,
                         VALUE AS BroadcastQueueTopic
                  FROM T_ParamValue PV
                  WHERE TypeID = 117 ) AS TB
       ON M.M_ID = TB.MgrID
     INNER JOIN T_MgrTypes MT
       ON M.M_TypeID = MT.MT_TypeID
     INNER JOIN ( SELECT MgrID,
                         CONVERT(varchar(128), VALUE) AS MessageQueueURI
                  FROM T_ParamValue AS PV
                  WHERE TypeID = 105 ) AS TM
       ON M.M_ID = TM.MgrID

GO
