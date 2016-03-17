/****** Object:  View [dbo].[V_Dataset_QC_Metric_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Dataset_QC_Metric_Instruments]
AS
SELECT IN_name AS Instrument,
       Instrument_ID      
FROM T_Dataset_QC_Instruments


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metric_Instruments] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Metric_Instruments] TO [PNL\D3M580] AS [dbo]
GO
