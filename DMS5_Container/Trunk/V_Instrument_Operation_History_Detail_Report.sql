/****** Object:  View [dbo].[V_Instrument_Operation_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Operation_History_Detail_Report
AS
SELECT     dbo.T_Instrument_Operation_History.ID, dbo.T_Instrument_Operation_History.Instrument, 
                      dbo.T_Users.U_Name + ' (' + dbo.T_Users.U_PRN + ')' AS Posted_By, dbo.T_Instrument_Operation_History.Entered, 
                      dbo.T_Instrument_Operation_History.Note
FROM         dbo.T_Instrument_Operation_History LEFT OUTER JOIN
                      dbo.T_Users ON dbo.T_Instrument_Operation_History.EnteredBy = dbo.T_Users.U_PRN

GO
