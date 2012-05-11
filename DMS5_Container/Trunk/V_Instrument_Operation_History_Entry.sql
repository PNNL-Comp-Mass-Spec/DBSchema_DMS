/****** Object:  View [dbo].[V_Instrument_Operation_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Operation_History_Entry
AS
SELECT     ID, Instrument, Entered, EnteredBy AS postedBy, Note
FROM         dbo.T_Instrument_Operation_History

GO
