/****** Object:  View [dbo].[V_EUS_Proposal_Users_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposal_Users_List_Report]
AS
SELECT PU.Person_ID AS [EUS Person ID],
       PU.Of_DMS_Interest AS [DMS Interest],
       U.NAME_FM AS Name,
       SS.Name AS [Site Status],
       PU.Proposal_ID AS [#EUS Proposal ID]
FROM dbo.T_EUS_Proposal_Users PU
     INNER JOIN dbo.T_EUS_Users U
       ON PU.Person_ID = U.PERSON_ID
     INNER JOIN dbo.T_EUS_Site_Status SS
       ON U.Site_Status = SS.ID
WHERE PU.State_ID <> 5


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users_List_Report] TO [PNL\D3M580] AS [dbo]
GO
