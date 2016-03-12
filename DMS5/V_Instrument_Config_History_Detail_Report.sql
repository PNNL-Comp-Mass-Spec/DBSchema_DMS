/****** Object:  View [dbo].[V_Instrument_Config_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Instrument_Config_History_Detail_Report] as
SELECT TIH.ID,
       TIH.Instrument,
       TIH.Date_Of_Change AS [Date of Change],
       CASE
           WHEN TU.U_PRN IS NULL THEN TIH.EnteredBy
           ELSE TU.Name_with_PRN
       END AS [Entered By],
       TIH.Entered,
       TIH.Description,
       TIH.Note
FROM T_Instrument_Config_History AS TIH
     LEFT OUTER JOIN T_Users AS TU
       ON TIH.EnteredBy = TU.U_PRN

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_History_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
