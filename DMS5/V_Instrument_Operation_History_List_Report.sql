/****** Object:  View [dbo].[V_Instrument_Operation_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Operation_History_List_Report
AS
SELECT     dbo.T_Instrument_Operation_History.ID, dbo.T_Instrument_Operation_History.Instrument, dbo.T_Instrument_Operation_History.Entered, 
                      dbo.T_Instrument_Operation_History.Note, dbo.T_Users.U_Name + ' (' + dbo.T_Users.U_PRN + ')' AS Posted_By
FROM         dbo.T_Instrument_Operation_History LEFT OUTER JOIN
                      dbo.T_Users ON dbo.T_Instrument_Operation_History.EnteredBy = dbo.T_Users.U_PRN

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Operation_History_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Operation_History_List_Report] TO [PNL\D3M580] AS [dbo]
GO
