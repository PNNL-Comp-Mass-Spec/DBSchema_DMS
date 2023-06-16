/****** Object:  View [dbo].[V_Run_Interval_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Run_Interval_Detail_Report]
AS
SELECT R.id,
       R.instrument,
       R.start,
       R.interval,
       R.comment,
       'UserRemote:' + U.User_Remote + '%' + Case When U.User_Remote <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  + '|' +
       'UserOnsite:' + U.User_Onsite + '%' + Case When U.User_Onsite <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  + '|' +
       'User:' + U.[user] + '%' + Case When U.[user] <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  + '|' +
       'Broken:' + U.Broken + '%|' +
       'Maintenance:' + U.Maintenance + '%|' +
       'StaffNotAvailable:' + U.Staff_Not_Available + '%|' +
       'CapDev:' + U.Cap_Dev + '%|' +
       'ResourceOwner:' + U.Resource_Owner + '%|' +
       'InstrumentAvailable:' + U.Instrument_Available + '%' AS usage,
       R.entered,
	   R.Last_Affected AS last_affected,
       R.entered_by
FROM dbo.T_Run_Interval R
     LEFT OUTER JOIN V_Run_Interval_Usage U
       ON R.ID = U.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
