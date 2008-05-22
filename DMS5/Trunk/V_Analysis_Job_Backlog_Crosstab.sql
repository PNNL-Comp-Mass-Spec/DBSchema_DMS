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
       IsNull([ICR2LS], 0) AS [ICR2LS],
       IsNull([LTQ_FTPek], 0) AS [LTQ_FTPek],
       IsNull([TIC_ICR], 0) AS [TIC_ICR],
       IsNull([AgilentTOFPek], 0) AS [AgilentTOFPek]
FROM ( SELECT AJT_ToolName,
              Convert(smalldatetime, Posting_time) AS Posting_time,
              Backlog_Count
       FROM V_Analysis_Job_Backlog_History ) AS SourceTable
     PIVOT ( Sum(Backlog_Count)
             FOR AJT_ToolName
             IN ( [Sequest], [XTandem], [Decon2LS], [MASIC_Finnigan], [ICR2LS], [LTQ_FTPek], 
             [TIC_ICR], [AgilentTOFPek] ) ) AS PivotData


GO
