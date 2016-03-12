/****** Object:  View [dbo].[V_Wellplate_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Wellplate_Entry AS 
 SELECT 
	ID AS ID,
	WP_Well_Plate_Num AS wellplateNum,
	WP_Description AS description,
	Created AS Created
FROM T_Wellplates
GO
GRANT VIEW DEFINITION ON [dbo].[V_Wellplate_Entry] TO [PNL\D3M578] AS [dbo]
GO
