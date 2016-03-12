/****** Object:  View [dbo].[V_Job_Step_State_Summary_Recent_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_State_Summary_Recent_Crosstab]
AS
SELECT PivotData.State,
       PivotData.StateName AS Job_State,
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
FROM ( SELECT Step_Tool,
              State,
              StateName,
              StepCount
       FROM V_Job_Step_State_Summary_Recent ) AS SourceTable
     PIVOT ( SUM(StepCount)
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
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_State_Summary_Recent_Crosstab] TO [PNL\D3M578] AS [dbo]
GO
