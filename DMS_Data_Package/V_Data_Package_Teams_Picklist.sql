/****** Object:  View [dbo].[V_Data_Package_Teams_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Data_Package_Teams_Picklist
As
SELECT Team_Name, Description
FROM T_Data_Package_Teams   


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Teams_Picklist] TO [DDL_Viewer] AS [dbo]
GO
