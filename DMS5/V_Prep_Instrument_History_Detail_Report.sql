/****** Object:  View [dbo].[V_Prep_Instrument_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Prep_Instrument_History_Detail_Report as
  SELECT
    dbo.T_Prep_Instrument_History.ID,
    dbo.T_Prep_Instrument_History.Instrument,
    dbo.T_Prep_Instrument_History.Date_Of_Change AS [Date of Change],
    dbo.T_Users.U_Name + ' (' + dbo.T_Prep_Instrument_History.EnteredBy + ')' AS [Entered By],
    dbo.T_Prep_Instrument_History.Entered,
    dbo.T_Prep_Instrument_History.Description,
    dbo.T_Prep_Instrument_History.Note
  FROM
    dbo.T_Prep_Instrument_History
    LEFT OUTER JOIN dbo.T_Users ON dbo.T_Prep_Instrument_History.EnteredBy = dbo.T_Users.U_PRN
GO
