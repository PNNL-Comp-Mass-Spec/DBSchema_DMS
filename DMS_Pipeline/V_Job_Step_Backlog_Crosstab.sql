/****** Object:  View [dbo].[V_Job_Step_Backlog_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Backlog_Crosstab]
AS
SELECT PivotData.Posting_Time,
       IsNull([DTA_Gen], 0) AS [DTA_Gen],
       IsNull([DTA_Refinery], 0) AS [DTA_Refinery],
       IsNull([Sequest], 0) AS [Sequest],
       IsNull([XTandem], 0) AS [XTandem],
       IsNull([MSGFPlus], 0) AS [MSGFPlus],
       IsNull([Decon2LS], 0) AS [Decon2LS],
       IsNull([Decon2LS_V2], 0) AS [Decon2LS_V2],
       IsNull([LTQ_FTPek], 0) AS [LTQ_FTPek],
       IsNull([MASIC_Finnigan], 0) AS [MASIC_Finnigan],
       IsNull([MSAlign], 0) AS [MSAlign],
	   IsNull([ProMex], 0) AS [ProMex],
	   IsNull([MSPathFinder], 0) AS [MSPathFinder],
	   IsNull([MODa], 0) AS [MODa],	   
       IsNull([Results_Transfer], 0) AS [Results_Transfer],
       IsNull([DataExtractor], 0) AS [DataExtractor],      
       IsNull([MSXML_Gen], 0) AS [MSXML_Gen]
FROM ( SELECT Convert(smalldatetime, Posting_time) AS Posting_Time,
              Step_Tool,
              Backlog_Count
       FROM V_Job_Step_Backlog_History 
     ) AS SourceTable
     PIVOT ( SUM(Backlog_Count)
             FOR Step_Tool
             IN ( [DTA_Gen], [DTA_Refinery],
                  [Sequest], [XTandem], [MSGFPlus],
                  [DataExtractor],
                  [Decon2LS],[Decon2LS_V2], [LTQ_FTPek],
                  [MASIC_Finnigan], [MSAlign], 
				  [ProMex], [MSPathFinder], [MODa],
                  [Results_Transfer], 
                  [MSXML_Gen] 
             ) ) AS PivotData




GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Backlog_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
