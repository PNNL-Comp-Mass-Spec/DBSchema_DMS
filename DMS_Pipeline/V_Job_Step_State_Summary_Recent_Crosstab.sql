/****** Object:  View [dbo].[V_Job_Step_State_Summary_Recent_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_State_Summary_Recent_Crosstab]
AS
SELECT PivotData.State,
       PivotData.StateName AS Job_State,
       IsNull([DataExtractor], 0) AS [DataExtractor],
       IsNull([Decon2LS_V2], 0) AS [Decon2LS_V2],
       IsNull([DTA_Gen], 0) AS [DTA_Gen],
       IsNull([DTA_Refinery], 0) AS [DTA_Refinery],
       IsNull([MASIC_Finnigan], 0) AS [MASIC_Finnigan],
       IsNull([MSGFPlus], 0) AS [MSGFPlus],
       IsNull([MSPathFinder], 0) AS [MSPathFinder],
       IsNull([MSXML_Gen], 0) AS [MSXML_Gen],
       IsNull([Mz_Refinery], 0) AS [Mz_Refinery],
       IsNull([PBF_Gen], 0) AS [PBF_Gen],
       IsNull([Phospho_FDR_Aggregator], 0) AS [Phospho_FDR_Aggregator],
       IsNull([PRIDE_Converter], 0) AS [PRIDE_Converter],
       IsNull([ProMex], 0) AS [ProMex],
       IsNull([SMAQC], 0) AS [SMAQC]
FROM ( SELECT Step_Tool,
              State,
              StateName,
              StepCount
       FROM V_Job_Step_State_Summary_Recent ) AS SourceTable
     PIVOT ( Sum(StepCount)
             FOR Step_Tool
             IN ( [DataExtractor], [Decon2LS_V2], [DTA_Gen], [DTA_Refinery], [MASIC_Finnigan], 
             [MSGFPlus], [MSPathFinder], [MSXML_Gen], [Mz_Refinery], [PBF_Gen], 
             [Phospho_FDR_Aggregator], [PRIDE_Converter], [ProMex], [SMAQC] ) ) AS PivotData

GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_State_Summary_Recent_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
