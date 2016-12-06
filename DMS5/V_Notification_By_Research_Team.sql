/****** Object:  View [dbo].[V_Notification_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_By_Research_Team]
AS
SELECT Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM V_Notification_Requested_Run_Batches_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM V_Notification_Analysis_Job_Request_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT Src.Seq, Src.Event, Src.Entity, Src.Name, Src.Campaign, Src.[User], Src.[Role], Src.Entered, Src.[#EntityType], Src.[#PRN]
FROM V_Notification_Analysis_Job_Request_By_Request_Owner Src
     LEFT OUTER JOIN ( SELECT Event, Entity, [#PRN]
                       FROM V_Notification_Analysis_Job_Request_By_Research_Team
                       WHERE Entered > DATEADD(HOUR, -24, GETDATE()) 
					 ) FilterQ
       ON Src.Event = FilterQ.Event AND
          Src.Entity = FilterQ.Entity AND
          Src.[#PRN] = FilterQ.[#PRN]
WHERE Entered > DATEADD(HOUR, -24, GETDATE()) AND
      FilterQ.[#PRN] IS NULL
UNION
SELECT Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM V_Notification_Sample_Prep_Request_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT Seq, Event, Entity, Name, Campaign, [User], Role, Entered, [#EntityType], [#PRN]
FROM V_Notification_Datasets_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE());


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
