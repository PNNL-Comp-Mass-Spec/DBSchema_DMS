/****** Object:  View [dbo].[V_Helper_Prep_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Helper_Prep_LC_Column_List_Report
AS
SELECT
	column_name,
	mfg_name,
	mfg_model,
	mfg_serial_number,
	comment,
	created
FROM T_Prep_LC_Column
WHERE state = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Column_List_Report] TO [DDL_Viewer] AS [dbo]
GO
