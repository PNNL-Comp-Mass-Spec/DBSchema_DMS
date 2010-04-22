/****** Object:  View [dbo].[V_Wellplate_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Wellplate_List_Report AS 
 SELECT 
	WP_Well_Plate_Num AS [Well Plate Number],
	WP_Description AS [Description],
	Created AS [Created]
FROM T_Wellplates

GO
GRANT VIEW DEFINITION ON [dbo].[V_Wellplate_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Wellplate_List_Report] TO [PNL\D3M580] AS [dbo]
GO
