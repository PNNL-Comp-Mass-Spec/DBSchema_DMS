/****** Object:  View [dbo].[V_Prep_LC_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Prep_LC_Run_Entry AS 
SELECT     ID, Tab, Instrument, Type, LC_Column AS LCColumn, LC_Column_2 AS LCColumn2, Comment, Guard_Column AS GuardColumn, Created, OperatorPRN, 
                      Digestion_Method AS DigestionMethod, Sample_Type AS SampleType, Number_Of_Runs AS NumberOfRuns, 
                      Instrument_Pressure AS InstrumentPressure, SamplePrepRequest
FROM         dbo.T_Prep_LC_Run
GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Entry] TO [PNL\D3M580] AS [dbo]
GO
