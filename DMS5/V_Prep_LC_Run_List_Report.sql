/****** Object:  View [dbo].[V_Prep_LC_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Prep_LC_Run_List_Report]
AS
SELECT id,
       Prep_Run_Name AS name,
       instrument,
       type,
       LC_Column AS lc_column,
       Comment AS comment,
       Guard_Column AS guard_column,
       Quality_Control AS qc,
       Created AS created,
       OperatorPRN AS operator_username,
       Digestion_Method AS digestion_method,
       Sample_Type AS sample_type,
       Sample_Prep_Requests AS sample_prep_requests,
       Sample_Prep_Work_Packages As work_packages,
       Number_Of_Runs AS number_of_runs,
       Instrument_Pressure AS instrument_pressure
FROM T_Prep_LC_Run

GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_LC_Run_List_Report] TO [DDL_Viewer] AS [dbo]
GO
