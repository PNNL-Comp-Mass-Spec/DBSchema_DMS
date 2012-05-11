/****** Object:  View [dbo].[V_Notification_Message_By_Registered_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Notification_Message_By_Registered_Users AS 
SELECT
  VNMRT.Event,
  VNMRT.Entity,
  VNMRT.Link,
  VNMRT.Name,
  VNMRT.Campaign,
  VNMRT.Role,
  VNMRT.EventTypeID,
  VNMRT.[#EntityType],
  VNMRT.[#PRN],
  VNMRT.[User],
  TNER.User_ID,
  VNMRT.Entered,
  TU.U_email AS Email
FROM
  T_Notification_Entity_User AS TNER
  INNER JOIN T_Users AS TU ON TNER.User_ID = TU.ID
  INNER JOIN V_Notification_Message_By_Research_Team AS VNMRT ON TU.U_PRN = VNMRT.[#PRN]
                                                              AND TNER.Entity_Type_ID = VNMRT.#EntityType
GO
