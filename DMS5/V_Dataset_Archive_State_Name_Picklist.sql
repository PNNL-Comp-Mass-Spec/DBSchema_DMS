/****** Object:  View [dbo].[V_Dataset_Archive_State_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Dataset_Archive_State_Name_Picklist
AS
SELECT DASN_StateID AS ID, DASN_StateName As Name 
FROM T_DatasetArchiveStateName 


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Archive_State_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
