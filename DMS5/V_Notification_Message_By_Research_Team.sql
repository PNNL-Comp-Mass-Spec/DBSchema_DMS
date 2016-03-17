/****** Object:  View [dbo].[V_Notification_Message_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Notification_Message_By_Research_Team
AS
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN], REPLACE(Link_Template, '@ID@', Entity) AS Link, 
                      EventTypeID
FROM         V_Notification_Requested_Run_Batches_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())
UNION
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN], REPLACE(Link_Template, '@ID@', Entity) AS Link, 
                      EventTypeID
FROM         V_Notification_Analysis_Job_Request_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())
UNION
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN], REPLACE(Link_Template, '@ID@', Entity) AS Link, 
                      EventTypeID
FROM         V_Notification_Sample_Prep_Request_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())
UNION
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN], REPLACE(Link_Template, '@ID@', Entity) AS Link, 
                      EventTypeID
FROM         V_Notification_Datasets_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())

GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Message_By_Research_Team] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Message_By_Research_Team] TO [PNL\D3M580] AS [dbo]
GO
