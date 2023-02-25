/****** Object:  View [dbo].[V_Prep_LC_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Prep_LC_Run_Entry]
AS
SELECT  id,
        prep_run_name,
        instrument,
        type,
        lc_column,
        lc_column_2,
        comment,
        guard_column,
        created,
        OperatorPRN AS operator_username,
        digestion_method,
        sample_type,
        number_of_runs,
        instrument_pressure,
        SamplePrepRequest AS sample_prep_request,
        quality_control,
        dbo.get_hplc_run_dataset_list(ID, 'name') AS datasets
FROM    T_Prep_LC_Run

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Entry] TO [DDL_Viewer] AS [dbo]
GO
