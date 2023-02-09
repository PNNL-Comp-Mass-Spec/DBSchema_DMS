/****** Object:  View [dbo].[V_Notification_Analysis_Job_Request_By_Request_Owner] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Analysis_Job_Request_By_Request_Owner] AS
SELECT DISTINCT TNE.ID AS seq,
                TET.Name AS event,
                AJR.AJR_requestID AS entity,
                AJR.AJR_requestName AS name,
                C.Campaign_Num AS campaign,
                U.U_Name AS person,
                'Request Owner' AS person_role,
                TNE.entered,
                TET.Target_Entity_Type AS entity_type,
                U.U_PRN AS username,
                TET.ID AS event_type,
                TNE.Event_Type AS event_type_id,
                TET.link_template
FROM T_Notification_Event TNE
     INNER JOIN T_Notification_Event_Type TET
       ON TET.ID = TNE.Event_Type
     INNER JOIN T_Analysis_Job_Request AJR
       ON TNE.Target_ID = AJR.AJR_requestID
     INNER JOIN T_Analysis_Job J
       ON AJR.AJR_requestID = J.AJ_requestID
     INNER JOIN T_Dataset DS
       ON J.AJ_datasetID = DS.Dataset_ID
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_Users U
       ON AJR.AJR_requestor = U.ID
WHERE TET.Target_Entity_Type = 2 AND
      TET.Visible = 'Y' AND
      U.U_active = 'Y'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Analysis_Job_Request_By_Request_Owner] TO [DDL_Viewer] AS [dbo]
GO
