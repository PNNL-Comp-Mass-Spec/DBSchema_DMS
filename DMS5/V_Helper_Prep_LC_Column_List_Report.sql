/****** Object:  View [dbo].[V_Helper_Prep_LC_Column_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Helper_Prep_LC_Column_List_Report AS 
 SELECT 
	Column_Name AS [Column Name],
	Mfg_Name AS [Mfg Name],
	Mfg_Model AS [Mfg Model],
	Mfg_Serial_Number AS [Mfg Serial Number],
	Comment AS [Comment],
	Created AS [Created]
FROM T_Prep_LC_Column
WHERE State = 'Active'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Column_List_Report] TO [PNL\D3M578] AS [dbo]
GO
