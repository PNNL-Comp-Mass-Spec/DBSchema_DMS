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
       PU.Last_Affected
FROM T_EUS_Proposal_Users PU
     INNER JOIN T_EUS_Users U
       ON PU.Person_ID = U.PERSON_ID
WHERE (PU.Of_DMS_Interest = 'Y')


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users] TO [PNL\D3M580] AS [dbo]
GO
