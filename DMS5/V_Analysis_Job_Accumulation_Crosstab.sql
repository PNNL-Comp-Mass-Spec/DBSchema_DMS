/****** Object:  View [dbo].[V_Analysis_Job_Accumulation_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Accumulation_Crosstab]
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
FROM ( SELECT Tool.AJT_toolName,
              Convert(smalldatetime, AJSH.Posting_Time) AS Posting_time,
              AJSH.Job_Count
       FROM dbo.T_Analysis_Job_Status_History AJSH
            INNER JOIN dbo.T_Analysis_Tool Tool
              ON AJSH.Tool_ID = Tool.AJT_toolID ) AS SourceTable
     PIVOT ( Sum(Job_Count)
             FOR AJT_ToolName
             IN ( [Sequest], [XTandem], [Decon2LS], [MASIC_Finnigan], [ICR2LS], [LTQ_FTPek], 
             [TIC_ICR], [AgilentTOFPek] ) ) AS PivotData

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Accumulation_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
