/****** Object:  View [dbo].[V_Instrument_Operation_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Operation_History_List_Report]
AS
SELECT H.id,
       H.instrument,
       H.entered,
       H.note,
       U.Name_with_PRN AS posted_by
FROM dbo.T_Instrument_Operation_History H
     LEFT OUTER JOIN dbo.T_Users U
       ON H.EnteredBy = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Operation_History_List_Report] TO [DDL_Viewer] AS [dbo]
GO
