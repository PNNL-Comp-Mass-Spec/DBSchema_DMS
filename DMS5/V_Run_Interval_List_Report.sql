/****** Object:  View [dbo].[V_Run_Interval_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Run_Interval_List_Report]
AS
SELECT R.ID,
       R.Instrument,
       R.Start,
       R.[Interval],
       R.[Comment],
       U.[UserRemote] + Case When U.[UserRemote] <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  AS [UserRemote],
       U.[UserOnsite] + Case When U.[UserOnsite] <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  AS [UserOnsite],
       U.[User] + Case When U.[User] <> '0' Then ' (Proposal ' + U.User_Proposal + ')' Else '' End  AS [User],
       U.Broken AS Broken,
       U.Maintenance AS Maintenance ,
       U.StaffNotAvailable AS StaffNotAvailable,
       U.CapDev AS CapDev,
       U.InstrumentAvailable AS InstrumentAvailable,
       R.Entered,
       R.Last_Affected,
       R.Entered_By
FROM dbo.T_Run_Interval R LEFT OUTER JOIN V_Run_Interval_Usage U ON R.ID = U.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Interval_List_Report] TO [DDL_Viewer] AS [dbo]
GO
