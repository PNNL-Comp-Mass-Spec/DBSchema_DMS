/****** Object:  View [dbo].[V_EUS_Users_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Users_List_Report]
AS
SELECT U.PERSON_ID AS ID,
       U.NAME_FM AS Name,
       SS.Name AS [Site Status],
       dbo.GetEUSUsersProposalList(U.PERSON_ID) AS Proposals,
       U.HID AS Hanford_ID,
       U.Valid As Valid_EUS_ID,
       U.Last_Affected
FROM T_EUS_Users U
     INNER JOIN T_EUS_Site_Status SS
       ON U.Site_Status = SS.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_List_Report] TO [DDL_Viewer] AS [dbo]
GO
