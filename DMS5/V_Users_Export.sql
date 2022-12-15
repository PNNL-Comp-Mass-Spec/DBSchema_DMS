/****** Object:  View [dbo].[V_Users_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Users_Export]
AS
SELECT U.ID,
       U.U_PRN AS Username,
       U.U_Name AS Name,
       U.U_HID AS Hanford_ID,
       U.U_Status AS Status,
       U.U_email AS EMail,
       U.U_Comment AS Comment,
       U.U_created AS Created_DMS,
       U.Name_with_PRN As Name_With_Username,
       U.U_active AS Active
FROM T_Users U      


GO
