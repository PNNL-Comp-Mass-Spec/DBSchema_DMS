/****** Object:  View [dbo].[V_EUS_Proposal_Users_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Proposal_Users_List_Report]
AS
SELECT PU.Person_ID AS eus_person_id,
       PU.Of_DMS_Interest AS dms_interest,
       U.NAME_FM AS name,
       SS.Name AS site_status,
       PU.Proposal_ID AS eus_proposal_id,
       U.First_Name AS first_name,
       U.Last_Name AS last_name
FROM dbo.T_EUS_Proposal_Users PU
     INNER JOIN dbo.T_EUS_Users U
       ON PU.Person_ID = U.PERSON_ID
     INNER JOIN dbo.T_EUS_Site_Status SS
       ON U.Site_Status = SS.ID
WHERE PU.State_ID <> 5


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Proposal_Users_List_Report] TO [DDL_Viewer] AS [dbo]
GO
