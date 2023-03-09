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
       TPR.OperatorPRN AS operator_username,
       TPR.Digestion_Method AS digestion_method,
       TPR.Sample_Type AS sample_type,
       TPR.Sample_Prep_Requests AS sample_prep_requests,
       TPR.Sample_Prep_Work_Packages As work_packages,
       TPR.Number_Of_Runs AS number_of_runs,
       dbo.get_prep_lc_experiment_groups_list(TPR.ID) AS experiment_groups,
       TPR.Instrument_Pressure AS instrument_pressure,
       dbo.get_hplc_run_dataset_list(TPR.id, 'name') AS datasets
FROM T_Prep_LC_Run AS TPR

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
