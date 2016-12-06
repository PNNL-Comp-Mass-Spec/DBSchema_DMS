/****** Object:  View [dbo].[V_Wellplate_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Wellplate_Picklist
AS
SELECT     WP_Well_Plate_Num + ',  ' + CAST(ISNULL(WP_Description, '') AS Char(48)) AS val, WP_Well_Plate_Num AS ex
FROM         dbo.T_Wellplates

GO
GRANT VIEW DEFINITION ON [dbo].[V_Wellplate_Picklist] TO [DDL_Viewer] AS [dbo]
GO
