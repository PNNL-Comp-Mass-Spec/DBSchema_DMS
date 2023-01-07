/****** Object:  View [dbo].[V_Helper_Prep_LC_Run_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Prep_LC_Run_List_Report]
AS
SELECT id,
       prep_run_name,
       instrument,
       type,
       lc_column,
       comment,
       created,
       number_of_runs
FROM T_Prep_LC_Run


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_List_Report] TO [DDL_Viewer] AS [dbo]
GO
