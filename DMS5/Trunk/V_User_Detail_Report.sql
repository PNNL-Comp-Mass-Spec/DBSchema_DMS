/****** Object:  View [dbo].[V_User_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_Detail_Report]
AS
SELECT U_PRN AS PRN,
       U_HID AS HID,
       U_Name AS Name,
       U_email AS Email,
       U_Status AS [Status],
       U_update as UserUpdate,
       dbo.GetUserOperationsList(ID) AS [Operations List],
       U_comment as Comment,
       ID,
       U_created AS Created_DMS
FROM dbo.T_Users


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
