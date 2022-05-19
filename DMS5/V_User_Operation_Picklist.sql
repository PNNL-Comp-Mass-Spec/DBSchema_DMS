/****** Object:  View [dbo].[V_User_Operation_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_User_Operation_Picklist
As
SELECT ID, Operation As Name, Operation_Description As Description
FROM T_User_Operations


GO
GRANT VIEW DEFINITION ON [dbo].[V_User_Operation_Picklist] TO [DDL_Viewer] AS [dbo]
GO
