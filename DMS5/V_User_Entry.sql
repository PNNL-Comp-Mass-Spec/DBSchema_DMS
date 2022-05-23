/****** Object:  View [dbo].[V_User_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_User_Entry]
AS
SELECT U_PRN AS username,
       U_HID AS hanford_id,
       'Last Name, First Name, and Email are auto-updated when "User Update" = Y' As entry_note,
       -- Obsolete: U_Payroll AS Payroll,
       U_Name AS last_name_first_name,
       U_email as email,
       U_Status AS user_status,
       U_update AS user_update,
       dbo.GetUserOperationsList(ID) AS operations_list,
       U_comment AS comment
FROM dbo.T_Users


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Entry] TO [DDL_Viewer] AS [dbo]
GO
