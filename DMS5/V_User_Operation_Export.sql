/****** Object:  View [dbo].[V_User_Operation_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_User_Operation_Export]
AS
SELECT U.ID,
       U.U_PRN AS Username,
       U.U_HID AS Hanford_ID,
       U.U_Name AS Name,
       U.U_Status AS Status,
       dbo.get_user_operations_list(U.ID) AS Operations_List,
       U.U_Comment as Comment,
       U.U_created AS Created_DMS,
       U.U_email AS EMail
FROM T_Users U

GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Operation_Export] TO [DDL_Viewer] AS [dbo]
GO
