/****** Object:  View [dbo].[V_EUS_Site_Status_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_EUS_Site_Status_Picklist
AS
SELECT ID, Name
FROM dbo.T_EUS_Site_Status


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Site_Status_Picklist] TO [DDL_Viewer] AS [dbo]
GO
