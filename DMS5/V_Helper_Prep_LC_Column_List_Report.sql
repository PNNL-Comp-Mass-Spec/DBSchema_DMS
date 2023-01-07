/****** Object:  View [dbo].[V_Helper_Prep_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Helper_Prep_LC_Column_List_Report
AS
SELECT
	Column_Name,
	Mfg_Name,
	Mfg_Model,
	Mfg_Serial_Number,
	Comment,
	Created
FROM T_Prep_LC_Column
WHERE State = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Column_List_Report] TO [DDL_Viewer] AS [dbo]
GO
