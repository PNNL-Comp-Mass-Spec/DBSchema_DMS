/****** Object:  View [dbo].[V_Instrument_Class_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Class_List_Report]
AS
SELECT IN_class AS [Instrument Class],
       is_purgable AS [Is Purgable],
       raw_data_type AS [Raw Data Type],
       requires_preparation AS [Requires Preparation],
       Comment
FROM dbo.T_Instrument_Class


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_List_Report] TO [PNL\D3M580] AS [dbo]
GO
