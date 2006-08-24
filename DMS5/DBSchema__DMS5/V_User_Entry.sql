/****** Object:  View [dbo].[V_User_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_User_Entry
AS
SELECT U_PRN AS [userPRN], U_HID AS hanfordID, 
   U_Name AS userName, U_Access_Lists AS accessList
FROM dbo.T_Users




GO
