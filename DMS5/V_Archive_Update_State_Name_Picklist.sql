/****** Object:  View [dbo].[V_Archive_Update_State_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Archive_Update_State_Name_Picklist
AS
SELECT AUS_StateID AS ID, AUS_name As Name
FROM T_Dataset_Archive_Update_State_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Archive_Update_State_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
