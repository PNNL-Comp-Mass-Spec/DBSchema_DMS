/****** Object:  View [dbo].[V_EUS_Proposal_Users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposal_Users]
AS
SELECT U.PERSON_ID AS [User ID],
       U.NAME_FM AS [User Name],
       PU.Proposal_ID AS [#Proposal],       
	   IsNull(UsageQ.Prep_Requests, 0) As [Prep Requests],
	   PU.Last_Affected As [Last_Affected]
FROM T_EUS_Proposal_Users PU
     INNER JOIN T_EUS_Users U
       ON PU.Person_ID = U.PERSON_ID
     LEFT OUTER JOIN ( -- This query counts the number of prep requests for which the EUS user is listed
	                   -- It ignores Prep Requests with multiple EUS users defined
					   -- Guidance as of May 2014 is that sample prep requests should only have a single EUS user listed
	                   SELECT EUS_User_List AS Person_ID,
                              Count(*) AS Prep_Requests
                       FROM T_Sample_Prep_Request
                       WHERE IsNull(EUS_User_List, '') <> '' AND
                             NOT EUS_User_List LIKE '%,%'
                       GROUP BY EUS_User_List ) AS UsageQ
       ON U.PERSON_ID = UsageQ.Person_ID
WHERE PU.Of_DMS_Interest = 'Y' AND
      PU.State_ID <> 5


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [PNL\D3M580] AS [dbo]
GO
