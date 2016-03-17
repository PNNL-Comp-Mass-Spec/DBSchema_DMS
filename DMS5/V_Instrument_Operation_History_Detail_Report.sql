/****** Object:  View [dbo].[V_Instrument_Operation_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Operation_History_Detail_Report]
AS
SELECT H.ID,
       H.Instrument,
       U.Name_with_PRN AS Posted_By,
       H.Entered,
       H.Note
FROM dbo.T_Instrument_Operation_History H
     LEFT OUTER JOIN dbo.T_Users U
       ON H.EnteredBy = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Operation_History_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Operation_History_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
