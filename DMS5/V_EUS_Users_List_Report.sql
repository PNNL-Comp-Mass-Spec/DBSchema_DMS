/****** Object:  View [dbo].[V_EUS_Users_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_EUS_Users_List_Report]
AS
SELECT U.PERSON_ID AS id,
       U.NAME_FM AS name,
       SS.Name AS site_status,
       dbo.get_eus_users_proposal_list(U.PERSON_ID) AS proposals,
       U.HID AS hanford_id,
       U.Valid As valid_eus_id,
       U.last_affected
FROM T_EUS_Users U
     INNER JOIN T_EUS_Site_Status SS
       ON U.Site_Status = SS.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_List_Report] TO [DDL_Viewer] AS [dbo]
GO
