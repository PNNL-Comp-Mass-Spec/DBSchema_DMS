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
       U.U_PRN AS [Username],
       U.U_HID AS [Hanford ID],
       U.U_Name AS Name,
       U.U_Status AS Status,
       dbo.GetUserOperationsList(U.ID) AS [Operations List],
       U.U_Comment as [Comment],
       U.U_created AS Created_DMS,
	   U.U_Payroll AS Payroll,	   
       EU.PERSON_ID AS EUS_ID,
       ESS.Name AS EUS_Status,
	   U.U_email AS EMail
FROM T_EUS_Site_Status ESS
     INNER JOIN T_EUS_Users EU
       ON ESS.ID = EU.Site_Status
     RIGHT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
