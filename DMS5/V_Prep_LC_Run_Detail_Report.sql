/****** Object:  View [dbo].[V_Prep_LC_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Prep_LC_Run_Detail_Report] as
SELECT TPR.ID,
       TPR.Tab,
       TPR.Instrument,
       TPR.[Type],
       TPR.LC_Column AS [LC Column],
       TPR.LC_Column_2 AS [LC Column 2],
       TPR.[Comment],
       TPR.Guard_Column AS [Guard Column],
       TPR.Quality_Control AS QC,
       TPR.Created,
       TPR.OperatorPRN,
       TPR.Digestion_Method AS [Digestion Method],
       TPR.Sample_Type AS [Sample Type],
       TPR.SamplePrepRequest AS [Sample Prep Request],
       TPR.Number_Of_Runs AS [Number Of Runs],
       dbo.GetPrepLCExperimentGroupsList(TPR.ID) AS [Experiment Groups],
       TPR.Instrument_Pressure AS [Instrument Pressure]
FROM T_Prep_LC_Run AS TPR


GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
