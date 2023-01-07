/****** Object:  View [dbo].[V_Instrument_Config_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Config_History_Detail_Report]
AS
SELECT TIH.id,
       TIH.instrument,
       Cast(TIH.Date_Of_Change AS date) AS date_of_change,
       CASE
           WHEN TU.U_PRN IS NULL THEN TIH.enteredby
           ELSE TU.name_with_prn
       END AS entered_by,
       TIH.entered,
       TIH.description,
       TIH.note
FROM T_Instrument_Config_History AS TIH
     LEFT OUTER JOIN T_Users AS TU
       ON TIH.EnteredBy = TU.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
