/****** Object:  View [dbo].[V_User_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_User_List_Report_2]
AS
SELECT U_PRN AS [Payroll Num],
       U_HID AS [Hanford ID],
       U_Name AS Name,
       U_Status AS Status,
       dbo.GetUserOperationsList(ID) AS [Operations List],
       U_Comment as Comment,
       ID,
       U.U_created AS Created_DMS
FROM dbo.T_Users AS U



GO
GRANT VIEW DEFINITION ON [dbo].[V_User_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_User_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO
