/****** Object:  View [dbo].[V_Instrument_Config_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Config_History_Entry
AS
SELECT     ID, Instrument, Description, Note, Entered, EnteredBy, Date_Of_Change AS DateOfChange
FROM         dbo.T_Instrument_Config_History

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_History_Entry] TO [PNL\D3M578] AS [dbo]
GO
