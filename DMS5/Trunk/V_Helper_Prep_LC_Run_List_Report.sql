/****** Object:  View [dbo].[V_Helper_Prep_LC_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Helper_Prep_LC_Run_List_Report AS 
SELECT        ID, Instrument, Type, LC_Column AS [LC Column], Comment, Created, Number_Of_Runs AS [Number Of Runs]
FROM            dbo.T_Prep_LC_Run
GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_List_Report] TO [PNL\D3M580] AS [dbo]
GO
