/****** Object:  View [dbo].[V_Prep_LC_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Prep_LC_Run_List_Report as
SELECT        ID, Tab, Instrument, Type, LC_Column AS [LC Column], Comment, Guard_Column AS [Guard Column], Quality_Control AS QC, Created, OperatorPRN, 
                         Digestion_Method AS [Digestion Method], Sample_Type AS [Sample Type], SamplePrepRequest AS [Sample Prep Request], Number_Of_Runs AS [Number Of Runs], 
                         Instrument_Pressure AS [Instrument Pressure]
FROM            T_Prep_LC_Run

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_List_Report] TO [DDL_Viewer] AS [dbo]
GO
