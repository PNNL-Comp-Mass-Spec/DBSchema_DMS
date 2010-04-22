/****** Object:  View [dbo].[V_Helper_Prep_LC_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Helper_Prep_LC_Run_List_Report AS 
 SELECT 
	ID AS [ID],
	Instrument AS [Instrument],
	Type AS [Type],
	LC_Column AS [LC Column],
	Comment AS [Comment],
	Created AS [Created],
	Project AS [Project],
	Number_Of_Runs AS [Number Of Runs]
FROM T_Prep_LC_Run

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_List_Report] TO [PNL\D3M580] AS [dbo]
GO
