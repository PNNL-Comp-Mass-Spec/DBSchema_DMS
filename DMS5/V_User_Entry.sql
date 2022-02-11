/****** Object:  View [dbo].[V_User_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_Entry]
AS
SELECT U_PRN AS Username,
       U_HID AS HanfordIDNum,
       'Last Name, First Name, and Email are auto-updated when "User Update" = Y' As EntryNote,
       -- Obsolete: U_Payroll AS Payroll,
       U_Name AS LastNameFirstName,
       U_email as Email,       
       U_Status AS UserStatus,
       U_update AS UserUpdate,
       dbo.GetUserOperationsList(ID) AS OperationsList,
       U_comment AS Comment
FROM dbo.T_Users


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Entry] TO [DDL_Viewer] AS [dbo]
GO
