/****** Object:  View [dbo].[V_Instrument_Config_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Config_History_List_Report]
AS
SELECT TIH.id,
       TIH.instrument,
       Cast(TIH.Date_Of_Change AS date) AS date_of_change,
       TIH.description,
       CASE
           WHEN DATALENGTH(TIH.Note) < 150 THEN Note
           ELSE SUBSTRING(TIH.note, 1, 150) + ' (more...)'
       END AS note,
       TIH.entered,
       CASE
           WHEN TU.U_PRN IS NULL THEN TIH.enteredby
           ELSE TU.name_with_prn
       END AS entered_by,
       TIH.Note AS note_full
FROM T_Instrument_Config_History AS TIH
     LEFT OUTER JOIN T_Users AS TU
       ON TIH.EnteredBy = TU.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_History_List_Report] TO [DDL_Viewer] AS [dbo]
GO
