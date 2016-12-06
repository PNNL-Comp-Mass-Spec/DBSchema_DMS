/****** Object:  View [dbo].[V_Processor_Tool_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Tool_Crosstab]
AS
SELECT PivotData.Processor_Name, 
       PivotData.Group_Name,
       PivotData.Group_ID,
       IsNull([DTA_Gen], '') AS [DTA_Gen],
       IsNull([Sequest], '') AS [Sequest],
       IsNull([XTandem], '') AS [XTandem],
       IsNull([Inspect], '') AS [Inspect],
       IsNull([Decon2LS], '') AS [Decon2LS],
       IsNull([Decon2LS_V2], '') AS [Decon2LS_V2],
       IsNull([MASIC_Finnigan], '') AS [MASIC_Finnigan],
       IsNull([MASIC_Agilent], '') AS [MASIC_Agilent],
       IsNull([DataExtractor], '') AS [DataExtractor],
       IsNull([InspectResultsAssembly], '') AS [InspectResultsAssembly],
       IsNull([Results_Transfer], '') AS [Results_Transfer],
       IsNull([MSXML_Gen], '') AS [MSXML_Gen],
       IsNull([MSMSSpectraPreprocessor], '') AS [MSMSSpectraPreprocessor],
       IsNull([MSGF], '') AS [MSGF],
       IsNull([MSGFDB], '') AS [MSGFDB],
       IsNull([MSDeconv], '') AS [MSDeconv],
       IsNull([MSAlign], '') AS [MSAlign],
       ISNULL([DTA_Split], '') AS [DTA_Split]
FROM ( SELECT LP.Processor_Name,
              PTG.Group_Name,
              PTG.Group_ID,
              PTGD.Tool_Name,
              Convert(varchar(12), PTGD.Priority) as Priority
		FROM T_Machines M
			 INNER JOIN T_Local_Processors LP
			   ON M.Machine = LP.Machine
			 INNER JOIN T_Processor_Tool_Groups PTG
			   ON M.ProcTool_Group_ID = PTG.Group_ID
			 INNER JOIN T_Processor_Tool_Group_Details PTGD
			   ON PTG.Group_ID = PTGD.Group_ID AND
				  LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
		WHERE PTGD.enabled > 0
       ) AS SourceTable
     PIVOT ( MIN(Priority)
             FOR Tool_Name
             IN ( [DTA_Gen], [DTA_Split], [DataExtractor], [Results_Transfer], [Sequest], [XTandem], [Inspect], 
             [InspectResultsAssembly], [Decon2LS], [Decon2LS_V2], [MASIC_Finnigan], [MASIC_Agilent], 
             [MSXML_Gen], [MSMSSpectraPreprocessor], [MSGF], [MSGFDB], [MSDeconv], [MSAlign] ) 
           ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Tool_Crosstab] TO [DDL_Viewer] AS [dbo]
GO
