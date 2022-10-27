/****** Object:  View [dbo].[V_EUS_Proposal_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposal_Users]
As
SELECT U.PERSON_ID AS [User ID],
       U.NAME_FM AS [User Name],
       PU.Proposal_ID AS #proposal,
       IsNull(UsageQ.Prep_Requests, 0) AS [Prep Requests],
       PU.Last_Affected AS [Last_Affected],
       P.Proposal_Start_Date,
       P.Proposal_End_Date
FROM T_EUS_Proposal_Users PU
     INNER JOIN T_EUS_Users U
       ON PU.Person_ID = U.Person_ID
     Inner Join T_EUS_Proposals P
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
