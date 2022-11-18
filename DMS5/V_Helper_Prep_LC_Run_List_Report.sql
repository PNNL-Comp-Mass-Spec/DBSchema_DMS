/****** Object:  View [dbo].[V_Helper_Prep_LC_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Prep_LC_Run_List_Report]
AS
SELECT ID,
       Prep_Run_Name,
       Instrument,
       [Type],
       LC_Column AS [LC Column],
       [Comment],
       Created,
       Number_Of_Runs AS [Number Of Runs]
FROM T_Prep_LC_Run


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_List_Report] TO [DDL_Viewer] AS [dbo]
GO
