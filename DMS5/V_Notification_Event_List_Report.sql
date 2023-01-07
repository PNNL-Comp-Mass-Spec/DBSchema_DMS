/****** Object:  View [dbo].[V_Notification_Event_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Notification_Event_List_Report
AS
SELECT
  T_Notification_Event.id,
  T_Notification_Event_Type.Name AS event,
  T_Notification_Event.Target_ID AS entity,
  T_Notification_Event.entered,
  T_Notification_Event_Type.Target_Entity_Type AS entity_type
FROM
  T_Notification_Event
  INNER JOIN T_Notification_Event_Type ON T_Notification_Event.Event_Type = T_Notification_Event_Type.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Event_List_Report] TO [DDL_Viewer] AS [dbo]
GO
