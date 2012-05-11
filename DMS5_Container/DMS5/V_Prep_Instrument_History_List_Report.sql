/****** Object:  View [dbo].[V_Prep_Instrument_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Prep_Instrument_History_List_Report as
SELECT
  dbo.T_Prep_Instrument_History.ID,
  dbo.T_Prep_Instrument_History.Instrument,
  dbo.T_Prep_Instrument_History.Date_Of_Change AS [Date of Change],
  dbo.T_Prep_Instrument_History.Description,
  CASE WHEN DATALENGTH(Note) < 200 THEN Note ELSE SUBSTRING(Note, 1, 200) + ' (more...)' END AS Note,
  dbo.T_Prep_Instrument_History.Entered,
  dbo.T_Users.U_Name + ' (' + dbo.T_Prep_Instrument_History.EnteredBy + ')' AS [Entered By]
FROM
  dbo.T_Prep_Instrument_History
  LEFT OUTER JOIN dbo.T_Users ON dbo.T_Prep_Instrument_History.EnteredBy = dbo.T_Users.U_PRN
GO
