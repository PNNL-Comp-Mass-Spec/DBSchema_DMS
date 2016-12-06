/****** Object:  View [dbo].[V_EMSL_Instruments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EMSL_Instruments
AS
SELECT EMSLInst.EUS_Display_Name,
       EMSLInst.EUS_Instrument_Name,
       EMSLInst.EUS_Instrument_ID,
       EMSLInst.Local_Instrument_Name,
       InstMap.DMS_Instrument_ID,
       DMSInstName.IN_name
FROM T_Instrument_Name DMSInstName
     INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMap
       ON DMSInstName.Instrument_ID = InstMap.DMS_Instrument_ID
     RIGHT OUTER JOIN T_EMSL_Instruments EMSLInst
       ON InstMap.EUS_Instrument_ID = EMSLInst.EUS_Instrument_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_EMSL_Instruments] TO [DDL_Viewer] AS [dbo]
GO
