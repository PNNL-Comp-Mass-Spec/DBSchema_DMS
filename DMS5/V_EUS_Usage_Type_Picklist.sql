/****** Object:  View [dbo].[V_EUS_Usage_Type_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Usage_Type_Picklist]
As
SELECT ID, Name, Description, Enabled_Campaign, Enabled_Prep_Request
FROM T_EUS_UsageType 
WHERE ID > 1 AND Enabled > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Usage_Type_Picklist] TO [DDL_Viewer] AS [dbo]
GO
