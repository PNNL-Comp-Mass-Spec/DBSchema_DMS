/****** Object:  View [dbo].[V_EUS_User_ID_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_User_ID_Lookup]
AS
SELECT U.U_PRN AS [Username],
       U.U_HID AS Hanford_ID,       
       U.U_Name AS Name,
       U.ID AS DMS_User_ID,
       U.U_created AS Created_DMS,
	   U.U_Status AS DMS_Status,
       LookupQ.EUS_Person_ID,
	   LookupQ.EUS_Name,
       LookupQ.EUS_Site_Status
FROM T_Users U
     INNER JOIN ( -- A few users have multiple EUS Person_ID values
                  -- We use LookupQ.RowRank = 1 when joining to this subquery to just keep one of those rows
                  -- This logic is also used by V_User_Detail_Report
                  SELECT EU.PERSON_ID AS EUS_Person_ID,
                         EU.NAME_FM AS EUS_Name,
                         ESS.Name AS EUS_Site_Status,
                         EU.HID AS EUS_Hanford_ID,                               
                         ROW_NUMBER() Over (Partition By EU.HID ORDER BY EU.PERSON_ID Desc) as RowRank
                  FROM T_EUS_Site_Status ESS
                       INNER JOIN T_EUS_Users EU
                         ON ESS.ID = EU.Site_Status 
                  WHERE NOT EU.HID IS Null 
                ) LookupQ
       ON LookupQ.EUS_Hanford_ID = U.U_HID AND LookupQ.RowRank = 1

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_User_ID_Lookup] TO [DDL_Viewer] AS [dbo]
GO
