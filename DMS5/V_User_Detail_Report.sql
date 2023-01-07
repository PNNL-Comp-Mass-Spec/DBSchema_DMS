/****** Object:  View [dbo].[V_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_Detail_Report]
AS
SELECT U.U_PRN AS username,
       U.U_HID AS hanford_id,
       U.U_Name AS name,
       -- Obsolete: U.U_Payroll AS payroll,
       U.U_email AS email,
       U.U_Status AS user_status,
       U.U_update AS user_update,
       dbo.GetUserOperationsList(U.ID) AS operations_list,
       U.U_comment AS comment,
       U.id,
       U.U_created AS created_dms,
       LookupQ.eus_person_id,
       LookupQ.eus_site_status,
       LookupQ.eus_last_affected
FROM T_Users U
     LEFT OUTER JOIN ( -- A few users have multiple EUS Person_ID values
                       -- We use LookupQ.RowRank = 1 when joining to this subquery to just keep one of those rows
                       -- This logic is also used by V_EUS_User_ID_Lookup
                       -- We also exclude users with EU.Valid = 0
                       SELECT EU.HID,
                              EU.PERSON_ID AS EUS_Person_ID,
                              ESS.Name AS EUS_Site_Status,
                              EU.Last_Affected AS EUS_Last_Affected,
                              ROW_NUMBER() Over (Partition By EU.HID ORDER BY EU.PERSON_ID Desc) AS RowRank
                       FROM T_EUS_Site_Status ESS
                            INNER JOIN T_EUS_Users EU
                              ON ESS.ID = EU.Site_Status
                       WHERE NOT EU.HID IS Null AND EU.Valid = 1
                     ) LookupQ
       ON LookupQ.HID = U.U_HID AND LookupQ.RowRank = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
