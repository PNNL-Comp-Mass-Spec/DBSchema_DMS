/****** Object:  View [dbo].[V_Instrument_Config_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Config_History_Detail_Report
AS
SELECT     ID, Instrument, Date_Of_Change AS [Date of Change], Description, Note, Entered, EnteredBy AS [Entered By]
FROM         dbo.T_Instrument_Config_History

GO
