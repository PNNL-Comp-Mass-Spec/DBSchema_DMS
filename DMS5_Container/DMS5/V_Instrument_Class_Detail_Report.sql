/****** Object:  View [dbo].[V_Instrument_Class_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Class_Detail_Report]
AS
SELECT IN_class AS [Instrument Class],
       is_purgable AS [Is Purgable],
       requires_preparation AS [Requires Preparation],
       raw_data_type,
       Comment,
       dbo.[XmlToHTML](Params) AS Params
FROM dbo.T_Instrument_Class


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
