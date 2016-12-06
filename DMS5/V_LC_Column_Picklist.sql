/****** Object:  View [dbo].[V_LC_Column_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_LC_Column_Picklist
AS
SELECT     SC_Column_Number AS val, '' AS ex
FROM         T_LC_Column
WHERE     (SC_State = 2)



GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_Picklist] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_LC_Column_Picklist] TO [DMS_LCMSNet_User] AS [dbo]
GO
