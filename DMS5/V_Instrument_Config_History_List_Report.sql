/****** Object:  View [dbo].[V_Instrument_Config_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Config_History_List_Report] as
SELECT TIH.ID,
       TIH.Instrument,
       Cast(TIH.Date_Of_Change AS date) AS [Date of Change],
       TIH.Description,
       CASE
           WHEN DATALENGTH(TIH.Note) < 150 THEN Note
           ELSE SUBSTRING(TIH.Note, 1, 150) + ' (more...)'
       END AS Note,
       TIH.Entered,
       CASE
           WHEN TU.U_PRN IS NULL THEN TIH.EnteredBy
           ELSE TU.Name_with_PRN
       END AS [Entered By],
       TIH.Note AS note_full
FROM T_Instrument_Config_History AS TIH
     LEFT OUTER JOIN T_Users AS TU
       ON TIH.EnteredBy = TU.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_History_List_Report] TO [DDL_Viewer] AS [dbo]
GO
