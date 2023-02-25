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
SELECT U.id,
       U.U_PRN AS username,
       U.U_HID AS hanford_id,
       U.U_Name AS name,
       U.U_Status AS status,
       dbo.get_user_operations_list(U.ID) AS operations_list,
       U.U_Comment AS comment,
       U.U_created AS created_dms,
       -- Obsolete: U.U_Payroll AS payroll,
       EU.PERSON_ID AS eus_id,
       EU.Valid AS valid_eus_id,
       ESS.Name AS eus_status,
       U.U_email AS email
FROM T_EUS_Site_Status ESS
     INNER JOIN T_EUS_Users EU
       ON ESS.ID = EU.Site_Status
     RIGHT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID

GO
GRANT VIEW DEFINITION ON [dbo].[V_User_List_Report_2] TO [DDL_Viewer] AS [dbo]
GO
