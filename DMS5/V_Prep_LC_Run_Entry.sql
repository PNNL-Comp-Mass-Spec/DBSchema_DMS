/****** Object:  View [dbo].[V_Prep_LC_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Prep_LC_Run_Entry]
AS
SELECT  id,
        tab,
        instrument,
        type,
        lc_column,
        lc_column_2,
        comment,
        guard_column,
        created,
        OperatorPRN AS operator_prn,
        digestion_method,
        sample_type,
        number_of_runs,
        instrument_pressure,
        SamplePrepRequest AS sample_prep_request,
        quality_control,
        dbo.GetHPLCRunDatasetList(ID, 'name') AS datasets
FROM    T_Prep_LC_Run


GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_Entry] TO [DDL_Viewer] AS [dbo]
GO
