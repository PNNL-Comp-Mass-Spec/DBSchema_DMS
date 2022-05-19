/****** Object:  View [dbo].[V_EUS_Site_Status_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Site_Status_Picklist]
AS
SELECT ID, Name, Cast(ID AS Varchar(32)) + ' - ' + Name As ID_with_Name
FROM dbo.T_EUS_Site_Status


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Site_Status_Picklist] TO [DDL_Viewer] AS [dbo]
GO
