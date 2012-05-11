/****** Object:  View [dbo].[V_Job_Step_Backlog_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Backlog_Crosstab]
AS
SELECT PivotData.Posting_Time,
       IsNull([DTA_Gen], 0) AS [DTA_Gen],
       IsNull([Sequest], 0) AS [Sequest],
       IsNull([XTandem], 0) AS [XTandem],
       IsNull([Inspect], 0) AS [Inspect],
       IsNull([Decon2LS], 0) AS [Decon2LS],
       IsNull([MASIC_Finnigan], 0) AS [MASIC_Finnigan],
       IsNull([Results_Transfer], 0) AS [Results_Transfer],
       IsNull([DataExtractor], 0) AS [DataExtractor],
       IsNull([InspectResultsAssembly], 0) AS [InspectResultsAssembly],
       IsNull([MSXML_Gen], 0) AS [MSXML_Gen]
FROM ( SELECT Convert(smalldatetime, Posting_time) AS Posting_Time,
              Step_Tool,
              Backlog_Count
       FROM V_Job_Step_Backlog_History 
     ) AS SourceTable
     PIVOT ( SUM(Backlog_Count)
             FOR Step_Tool
             IN ( [DTA_Gen], 
                  [Sequest], [XTandem], [Inspect], 
                  [DataExtractor], [InspectResultsAssembly], 
                  [Decon2LS],
                  [MASIC_Finnigan],
                  [Results_Transfer], 
                  [MSXML_Gen] 
             ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Backlog_Crosstab] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Backlog_Crosstab] TO [PNL\D3M580] AS [dbo]
GO
