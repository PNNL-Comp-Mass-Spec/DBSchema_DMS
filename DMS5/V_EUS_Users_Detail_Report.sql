/****** Object:  View [dbo].[V_EUS_Users_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Users_Detail_Report]
AS
SELECT EU.PERSON_ID AS id,
       EU.NAME_FM AS name,
       EU.HID AS hanford_id,
       SS.Name AS site_status,
       EU.last_affected,
       U.U_PRN AS prn,
       U.ID AS dms_user_id
FROM T_EUS_Users EU
     INNER JOIN T_EUS_Site_Status SS
       ON EU.Site_Status = SS.ID
     LEFT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
