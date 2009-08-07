/****** Object:  View [dbo].[V_Prep_LC_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Prep_LC_Run_Entry
AS
SELECT     ID, Tab, Instrument, Type, LC_Column AS LCColumn, Comment, Guard_Column AS GuardColumn, Created, OperatorPRN, 
                      Digestion_Method AS DigestionMethod, Sample_Type AS SampleType, Project, Number_Of_Runs AS NumberOfRuns, 
                      Instrument_Pressure AS InstrumentPressure
FROM         dbo.T_Prep_LC_Run

GO
