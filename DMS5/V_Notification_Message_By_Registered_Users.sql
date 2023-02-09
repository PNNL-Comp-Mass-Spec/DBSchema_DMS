/****** Object:  View [dbo].[V_Notification_Message_By_Registered_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Message_By_Registered_Users] AS
SELECT
  VNMRT.event,
  VNMRT.entity,
  VNMRT.link,
  VNMRT.name,
  VNMRT.campaign,
  VNMRT.person_role,
  VNMRT.event_type_id,
  VNMRT.entity_type,
  VNMRT.username,
  VNMRT.person,
  TNER.user_id,
  VNMRT.entered,
  TU.U_email AS email
FROM
  T_Notification_Entity_User AS TNER
  INNER JOIN T_Users AS TU ON TNER.User_ID = TU.ID
  INNER JOIN V_Notification_Message_By_Research_Team AS VNMRT
      ON TU.U_PRN = VNMRT.username AND
      TNER.Entity_Type_ID = VNMRT.Entity_Type

GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Message_By_Registered_Users] TO [DDL_Viewer] AS [dbo]
GO
