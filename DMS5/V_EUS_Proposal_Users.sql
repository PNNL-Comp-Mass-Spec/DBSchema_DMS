/****** Object:  View [dbo].[V_EUS_Proposal_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposal_Users]
AS
SELECT U.PERSON_ID AS user_id,
       U.NAME_FM AS user_name,
       PU.Proposal_ID AS proposal,
       IsNull(UsageQ.prep_requests, 0) AS prep_requests,
       PU.Last_Affected AS last_affected,
       P.proposal_start_date,
       P.proposal_end_date,
       -- The following are old column names, included for compatibility with Buzzard
       U.PERSON_ID AS [User ID],
       U.NAME_FM AS [User Name],
       PU.Proposal_ID As [#Proposal]
FROM T_EUS_Proposal_Users PU
     INNER JOIN T_EUS_Users U
       ON PU.Person_ID = U.Person_ID
     INNER JOIN T_EUS_Proposals P
       On PU.Proposal_ID = P.Proposal_ID
     LEFT OUTER JOIN ( SELECT EUS_User_ID AS Person_ID,
                              Count(*) AS Prep_Requests
                       FROM T_Sample_Prep_Request
                       WHERE NOT EUS_User_ID IS NULL
                       GROUP BY EUS_User_ID ) AS UsageQ
       ON U.PERSON_ID = UsageQ.Person_ID
WHERE PU.Of_DMS_Interest = 'Y' AND
      PU.State_ID <> 5


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [DDL_Viewer] AS [dbo]
GO
