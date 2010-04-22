/****** Object:  View [dbo].[V_Prep_LC_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Prep_LC_Run_Detail_Report
AS
SELECT     ID, Tab, Instrument, Type, LC_Column AS [LC Column], Comment, Guard_Column AS [Guard Column], Created, OperatorPRN, 
                      Digestion_Method AS [Digestion Method], Sample_Type AS [Sample Type], Project, Number_Of_Runs AS [Number Of Runs], 
                      Instrument_Pressure AS [Instrument Pressure]
FROM         dbo.T_Prep_LC_Run

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
