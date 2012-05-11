/****** Object:  View [dbo].[V_DMS_Instrument_Class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_Instrument_Class
AS
SELECT IN_class AS InstrumentClass,
       Params,
       raw_data_type
FROM S_DMS_T_Instrument_Class

GO
