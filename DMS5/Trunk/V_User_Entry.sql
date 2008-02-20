/****** Object:  View [dbo].[V_User_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_User_Entry
AS
SELECT     U_PRN AS UserPRN, U_Name AS UserName, U_HID AS HanfordIDNum, U_Status AS UserStatus, U_update AS UserUpdate, 
                      dbo.GetUserOperationsList(ID) AS OperationsList
FROM         dbo.T_Users

GO
