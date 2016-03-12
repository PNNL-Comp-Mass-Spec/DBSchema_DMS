/****** Object:  View [dbo].[V_Instrument_Config_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Config_List_Report]
AS
SELECT IN_name AS Instrument,
       IN_status AS Status,
       IN_Description AS Description,
       IN_usage AS [Usage],
       IN_operations_role AS Operations
FROM T_Instrument_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_List_Report] TO [PNL\D3M578] AS [dbo]
GO
