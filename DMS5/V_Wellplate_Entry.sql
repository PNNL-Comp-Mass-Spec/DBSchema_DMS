/****** Object:  View [dbo].[V_Wellplate_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Wellplate_Entry
AS
SELECT
	id,
	WP_Well_Plate_Num AS wellplate,
	WP_Description AS description,
	created
FROM T_Wellplates

GO
GRANT VIEW DEFINITION ON [dbo].[V_Wellplate_Entry] TO [DDL_Viewer] AS [dbo]
GO
