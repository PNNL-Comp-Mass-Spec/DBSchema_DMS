/****** Object:  View [dbo].[V_Prep_Instrument_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Prep_Instrument_History_Entry
AS
SELECT     ID, Instrument, Description, Note, Entered, EnteredBy, Date_Of_Change AS DateOfChange
FROM         dbo.T_Prep_Instrument_History


GO
