/****** Object:  View [dbo].[V_Instrument_Config_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Config_History_Entry]
AS
SELECT id,
       instrument,
       description,
       note,
       entered,
       EnteredBy AS posted_by,
       Cast(Date_Of_Change AS date) AS date_of_change
FROM T_Instrument_Config_History


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Config_History_Entry] TO [DDL_Viewer] AS [dbo]
GO
