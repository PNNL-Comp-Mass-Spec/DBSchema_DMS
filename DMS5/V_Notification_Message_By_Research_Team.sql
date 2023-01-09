/****** Object:  View [dbo].[V_Notification_Message_By_Research_Team] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Message_By_Research_Team]
AS
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, prn,
       REPLACE(Link_Template, '@ID@', Entity) AS link, event_type_id
FROM V_Notification_Requested_Run_Batches_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, prn,
       REPLACE(Link_Template, '@ID@', Entity) AS link, event_type_id
FROM V_Notification_Analysis_Job_Request_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT src.seq, src.event, src.entity, src.name, src.campaign, src.person, src.person_role, src.entered, src.entity_type, src.prn,
       REPLACE(Src.Link_Template, '@ID@', Src.Entity) AS link, src.event_type_id
FROM V_Notification_Analysis_Job_Request_By_Request_Owner Src
     LEFT OUTER JOIN ( SELECT Event, Entity, prn
                       FROM V_Notification_Analysis_Job_Request_By_Research_Team
                       WHERE Entered > DATEADD(HOUR, -24, GETDATE())
					 ) FilterQ
       ON Src.Event = FilterQ.Event AND
          Src.Entity = FilterQ.Entity AND
          Src.prn = FilterQ.prn
WHERE Entered > DATEADD(HOUR, -24, GETDATE()) AND
      FilterQ.prn IS NULL
UNION
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, prn,
       REPLACE(Link_Template, '@ID@', Entity) AS link, event_type_id
FROM V_Notification_Sample_Prep_Request_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())
UNION
SELECT seq, event, entity, name, campaign, person, person_role, entered, entity_type, prn,
       REPLACE(Link_Template, '@ID@', Entity) AS link, event_type_id
FROM V_Notification_Datasets_By_Research_Team
WHERE Entered > DATEADD(HOUR, -24, GETDATE())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Message_By_Research_Team] TO [DDL_Viewer] AS [dbo]
GO
