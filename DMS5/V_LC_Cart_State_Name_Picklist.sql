/****** Object:  View [dbo].[V_LC_Cart_State_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_LC_Cart_State_Name_Picklist
As
SELECT ID, Name
FROM T_LC_Cart_State_Name 
WHERE ID > 1


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_State_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
