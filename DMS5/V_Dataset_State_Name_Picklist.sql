/****** Object:  View [dbo].[V_Dataset_State_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Dataset_State_Name_Picklist
AS
SELECT Dataset_state_ID As ID, DSS_name As Name
FROM T_DatasetStateName


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_State_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
