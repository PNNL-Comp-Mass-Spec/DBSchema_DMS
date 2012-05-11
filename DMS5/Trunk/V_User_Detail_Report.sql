/****** Object:  View [dbo].[V_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_Detail_Report]
AS
SELECT U.U_PRN AS PRN,
       U.U_HID AS HID,
       U.U_Name AS Name,
       U.U_email AS Email,
       U.U_Status AS Status,
       U.U_update AS UserUpdate,
       dbo.GetUserOperationsList(U.ID) AS [Operations List],
       U.U_comment AS [Comment],
       U.ID,
       U.U_created AS Created_DMS,
       EU.EUS_Person_ID,
       EU.EUS_Site_Status,
       EU.EUS_Last_Affected
FROM T_Users U
     LEFT OUTER JOIN ( -- A few users have multiple EUS Person_ID values
                       -- We use EU.RowRank = 1 when joining to this subquery to just keep one of those rows
                       SELECT EU.HID, 
                              EU.PERSON_ID AS EUS_Person_ID,
                              ESS.Name AS EUS_Site_Status,
                              EU.Last_Affected AS EUS_Last_Affected,
                              ROW_NUMBER() Over (Partition By EU.HID ORDER BY EU.PERSON_ID Desc) as RowRank
                       FROM T_EUS_Site_Status ESS
                            INNER JOIN T_EUS_Users EU
                              ON ESS.ID = EU.Site_Status ) EU
       ON EU.HID = U.U_HID AND EU.RowRank = 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
