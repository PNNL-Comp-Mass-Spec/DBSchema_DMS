/****** Object:  View [dbo].[V_Campaign_List_Stale] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Campaign_List_Stale]
AS
SELECT ID, 
       Campaign,
       State,
       [Most Recent Activity],
       [Most Recent Sample Prep Request],
       [Most Recent Experiment],
       [Most Recent Run Request],
       [Most Recent Dataset],
       [Most Recent Analysis Job],
       Created
FROM V_Campaign_Detail_Report_Ex
WHERE (ISNULL([Most Recent Sample Prep Request], '1/1/2000') <= DATEADD(MONTH, -18, GETDATE())) AND
      (ISNULL([Most Recent Experiment], '1/1/2000') <= DATEADD(MONTH, -18, GETDATE())) AND
      (ISNULL([Most Recent Run Request], '1/1/2000') <= DATEADD(MONTH, -18, GETDATE())) AND
      (ISNULL([Most Recent Dataset], '1/1/2000') <= DATEADD(MONTH, -18, GETDATE())) AND
      (ISNULL([Most Recent Analysis Job], '1/1/2000') <= DATEADD(MONTH, -7, GETDATE())) AND
      (Created < '1/1/2009')


GO
