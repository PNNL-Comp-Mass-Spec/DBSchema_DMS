/****** Object:  View [dbo].[V_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_Detail_Report]
AS
SELECT U.U_PRN AS [Username],
       U.U_HID AS [Hanford ID],       
       U.U_Name AS Name,
       U.U_Payroll AS Payroll,
       U.U_email AS Email,
       U.U_Status AS [User Status],
       U.U_update AS [User Update],
       dbo.GetUserOperationsList(U.ID) AS [Operations List],
       U.U_comment AS [Comment],
       U.ID,
       U.U_created AS Created_DMS,
       LookupQ.EUS_Person_ID,
       LookupQ.EUS_Site_Status,
       LookupQ.EUS_Last_Affected
FROM T_Users U
     LEFT OUTER JOIN ( -- A few users have multiple EUS Person_ID values
                       -- We use LookupQ.RowRank = 1 when joining to this subquery to just keep one of those rows
                       -- This logic is also used by V_EUS_User_ID_Lookup
                       SELECT EU.HID, 
                              EU.PERSON_ID AS EUS_Person_ID,
                              ESS.Name AS EUS_Site_Status,
                              EU.Last_Affected AS EUS_Last_Affected,
                              ROW_NUMBER() Over (Partition By EU.HID ORDER BY EU.PERSON_ID Desc) as RowRank
                       FROM T_EUS_Site_Status ESS
                            INNER JOIN T_EUS_Users EU
                              ON ESS.ID = EU.Site_Status 
                       WHERE NOT EU.HID IS Null 
                     ) LookupQ
       ON LookupQ.HID = U.U_HID AND LookupQ.RowRank = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
