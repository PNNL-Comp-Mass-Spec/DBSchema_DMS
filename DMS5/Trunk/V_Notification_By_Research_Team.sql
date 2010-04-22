/****** Object:  View [dbo].[V_Notification_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Notification_By_Research_Team
AS
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM         V_Notification_Requested_Run_Batches_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())
UNION
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM         V_Notification_Analysis_Job_Request_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())
UNION
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM         V_Notification_Sample_Prep_Request_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())
UNION
SELECT     Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM         V_Notification_Datasets_By_Research_Team
WHERE     Entered > DATEADD(HOUR, - 24, GETDATE())



GO
