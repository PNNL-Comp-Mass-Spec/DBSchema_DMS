/****** Object:  View [dbo].[V_Notification_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_By_Research_Team]
AS
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, username
FROM V_Notification_Requested_Run_Batches_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, username
FROM V_Notification_Analysis_Job_Request_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT Src.seq, Src.event, Src.entity, Src.name, Src.campaign, Src.person, Src.person_role, Src.entered, Src.entity_type, Src.username
FROM V_Notification_Analysis_Job_Request_By_Request_Owner Src
     LEFT OUTER JOIN ( SELECT Event, Entity, username
                       FROM V_Notification_Analysis_Job_Request_By_Research_Team
                       WHERE Entered > DATEADD(HOUR, -24, GETDATE())
					 ) FilterQ
       ON Src.Event = FilterQ.Event AND
          Src.Entity = FilterQ.Entity AND
          Src.username = FilterQ.username
WHERE Entered > DATEADD(HOUR, -24, GETDATE()) AND
      FilterQ.username IS NULL
UNION
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, username
FROM V_Notification_Sample_Prep_Request_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, username
FROM V_Notification_Datasets_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE());

GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
