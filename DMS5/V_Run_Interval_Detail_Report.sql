/****** Object:  View [dbo].[V_Run_Interval_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Interval_Detail_Report]
AS
SELECT R.ID,
       R.Instrument,
       R.Start,
       R.[Interval],
       R.[Comment],
       'User:' + U.[User] + '%' + Case When U.[User] <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  + '|' +
       'Broken:' + U.Broken + '%|' +
       'Maintenance:' + U.Maintenance + '%|' +
       'StaffNotAvailable:' + U.StaffNotAvailable + '%|' +
       'CapDev:' + U.CapDev + '%|' +
       'InstrumentAvailable:' + U.InstrumentAvailable + '%' AS Usage,
       Entered
FROM dbo.T_Run_Interval R LEFT OUTER JOIN V_Run_Interval_Usage U ON R.ID = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
