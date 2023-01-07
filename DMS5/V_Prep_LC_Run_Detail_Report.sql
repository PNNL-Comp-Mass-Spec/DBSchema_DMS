/****** Object:  View [dbo].[V_Prep_LC_Run_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Prep_LC_Run_Detail_Report]
AS
SELECT TPR.id,
       TPR.Prep_Run_Name AS name,
       TPR.instrument,
       TPR.type,
       TPR.LC_Column AS lc_column,
       TPR.LC_Column_2 AS lc_column_2,
       TPR.comment,
       TPR.Guard_Column AS guard_column,
       TPR.Quality_Control AS qc,
       TPR.created,
       TPR.OperatorPRN AS operator_prn,
       TPR.Digestion_Method AS digestion_method,
       TPR.Sample_Type AS sample_type,
       TPR.SamplePrepRequest AS sample_prep_request,
       TPR.Number_Of_Runs AS number_of_runs,
       dbo.GetPrepLCExperimentGroupsList(TPR.ID) AS experiment_groups,
       TPR.Instrument_Pressure AS instrument_pressure,
       dbo.GetHPLCRunDatasetList(TPR.id, 'name') AS datasets
FROM T_Prep_LC_Run AS TPR


GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
