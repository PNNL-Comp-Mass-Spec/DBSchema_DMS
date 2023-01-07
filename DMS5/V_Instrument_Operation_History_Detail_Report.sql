/****** Object:  View [dbo].[V_Instrument_Operation_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Operation_History_Detail_Report]
AS
SELECT H.id,
       H.instrument,
       U.Name_with_PRN AS posted_by,
       H.entered,
       H.note
FROM dbo.T_Instrument_Operation_History H
     LEFT OUTER JOIN dbo.T_Users U
       ON H.EnteredBy = U.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Operation_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
