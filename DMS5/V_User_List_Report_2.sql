/****** Object:  View [dbo].[V_User_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_List_Report_2]
AS
-- Note that a few DMS Users have multiple EUS Person_ID values
-- That leads to duplicate rows in this report, 
--   but it doesn't hurt anything (and is actually informative)
SELECT U.ID,
       U.U_PRN AS [Payroll Num],
       U.U_HID AS [Hanford ID],
       U.U_Name AS Name,
       U.U_Status AS Status,
       dbo.GetUserOperationsList(U.ID) AS [Operations List],
       U.U_Comment as [Comment],
       U.U_created AS Created_DMS,
       EU.PERSON_ID AS EUS_Person_ID,
       ESS.Name AS EUS_Site_Status
FROM T_EUS_Site_Status ESS
     INNER JOIN T_EUS_Users EU
       ON ESS.ID = EU.Site_Status
     RIGHT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_User_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO
