/****** Object:  View [dbo].[V_Analysis_Job_Backlog_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Backlog_Crosstab]
AS
SELECT PivotData.Posting_Time,
       IsNull([Sequest], 0) AS [Sequest],
       IsNull([XTandem], 0) AS [XTandem],
       IsNull([Decon2LS], 0) AS [Decon2LS],
       IsNull([MASIC_Finnigan], 0) AS [MASIC_Finnigan],
       IsNull([Inspect], 0) AS [Inspect],
       IsNull([ICR2LS], 0) AS [ICR2LS],
       IsNull([LTQ_FTPek], 0) AS [LTQ_FTPek],
       IsNull([TIC_ICR], 0) AS [TIC_ICR],
       IsNull([AgilentTOFPek], 0) AS [AgilentTOFPek],
       IsNull([MSClusterDAT_Gen], 0) AS [MSClusterDAT_Gen]
FROM ( SELECT Tool_Name,
              Convert(smalldatetime, Posting_time) AS Posting_time,
              Backlog_Count
       FROM V_Analysis_Job_Backlog_History ) AS SourceTable
     PIVOT ( Sum(Backlog_Count)
             FOR Tool_Name
             IN ( [Sequest], [XTandem], [Decon2LS], [MASIC_Finnigan], [Inspect], [ICR2LS], [LTQ_FTPek],
             [TIC_ICR], [AgilentTOFPek], [MSClusterDAT_Gen] ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Backlog_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
