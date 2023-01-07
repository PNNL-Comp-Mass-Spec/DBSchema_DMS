/****** Object:  View [dbo].[V_Run_Interval_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Interval_List_Report]
AS
SELECT R.id,
       R.instrument,
       R.start,
       R.interval,
       R.comment,
       U.User_Remote + Case When U.User_Remote <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End AS user_remote,
       U.User_Onsite + Case When U.User_Onsite <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End AS user_onsite,
       U.[user] + Case When U.[user] <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End AS [user],
       U.Broken AS broken,
       U.Maintenance AS maintenance,
       U.Staff_Not_Available AS staff_not_available,
       U.Cap_Dev AS cap_dev,
       U.Instrument_Available AS instrument_available,
       R.entered,
       R.last_affected,
       R.entered_by
FROM dbo.T_Run_Interval R LEFT OUTER JOIN V_Run_Interval_Usage U ON R.ID = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_List_Report] TO [DDL_Viewer] AS [dbo]
GO
