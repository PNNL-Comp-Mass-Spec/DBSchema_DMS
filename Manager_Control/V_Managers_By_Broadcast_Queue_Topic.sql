/****** Object:  View [dbo].[V_Managers_By_Broadcast_Queue_Topic] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Managers_By_Broadcast_Queue_Topic]
AS
SELECT M.M_Name AS mgr_name,
       MT.MT_TypeName AS mgr_type,
       TB.BroadcastQueueTopic AS broadcast_topic,
       TM.MessageQueueURI AS msg_queue_uri
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
