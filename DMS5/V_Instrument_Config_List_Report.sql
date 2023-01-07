/****** Object:  View [dbo].[V_Instrument_Config_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Config_List_Report]
AS
SELECT IN_name AS instrument,
       IN_status AS status,
       IN_Description AS description,
       IN_usage AS usage,
       IN_operations_role AS operations
FROM T_Instrument_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_List_Report] TO [DDL_Viewer] AS [dbo]
GO
