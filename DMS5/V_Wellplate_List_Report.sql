/****** Object:  View [dbo].[V_Wellplate_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Wellplate_List_Report]
AS
SELECT
    id,
	WP_Well_Plate_Num AS wellplate_name,
	WP_Description AS description,
	created
FROM T_Wellplates


GO
GRANT VIEW DEFINITION ON [dbo].[V_Wellplate_List_Report] TO [DDL_Viewer] AS [dbo]
GO
