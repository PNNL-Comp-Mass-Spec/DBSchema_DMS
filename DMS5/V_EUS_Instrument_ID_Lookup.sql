/****** Object:  View [dbo].[V_EUS_Instrument_ID_Lookup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EUS_Instrument_ID_Lookup
AS
SELECT Inst.Instrument_ID,
       Inst.IN_name AS Instrument_Name,
       EDM.EUS_Instrument_ID
FROM dbo.T_EMSL_DMS_Instrument_Mapping EDM
     INNER JOIN dbo.T_Instrument_Name Inst
       ON EDM.DMS_Instrument_ID = Inst.Instrument_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Instrument_ID_Lookup] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Instrument_ID_Lookup] TO [PNL\D3M580] AS [dbo]
GO
