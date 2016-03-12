/****** Object:  View [dbo].[V_EUS_Users_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_EUS_Users_Detail_Report]
AS
SELECT EU.PERSON_ID AS ID,
       EU.NAME_FM AS Name,
       EU.HID AS Hanford_ID,
       SS.Name AS [Site Status],
       EU.Last_Affected,
       U.U_PRN AS PRN,
       U.ID AS DMS_User_ID
FROM T_EUS_Users EU
     INNER JOIN T_EUS_Site_Status SS
       ON EU.Site_Status = SS.ID
     LEFT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
