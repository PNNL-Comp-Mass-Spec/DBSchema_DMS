/****** Object:  View [dbo].[V_User_Status_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_User_Status_Picklist
As
SELECT User_Status As Status, Status_Description AS Description
FROM T_User_Status 


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Status_Picklist] TO [DDL_Viewer] AS [dbo]
GO
