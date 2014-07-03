/****** Object:  View [dbo].[V_Filter_Set_Criteria_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Filter_Set_Criteria_Crosstab]
AS
SELECT PivotData.Filter_Set_ID,
	   Filter_Set_Name,
	   Filter_Set_Description,
	   Filter_Criteria_Group_ID,
	   IsNull([Charge], 0) AS [Charge],
	   IsNull([High_Normalized_Score], 0) AS [High_Normalized_Score],
	   IsNull([Cleavage_State], 0) AS [Cleavage_State],
	   IsNull([Terminus_State], 0) AS [Terminus_State],
	   IsNull([DelCn], 0) AS [DelCn],
	   IsNull([DelCn2], 0) AS [DelCn2],
	   IsNull([RankScore], 0) AS [RankScore],
	   IsNull([XTandem_Hyperscore], 0) AS [XTandem_Hyperscore],
	   IsNull([XTandem_LogEValue], 0) AS [XTandem_LogEValue],
	   IsNull([Peptide_Prophet_Probability], 0) AS [Peptide_Prophet_Probability],
	   IsNull([MSGF_SpecProb], 0) AS [MSGF_SpecProb],
	   IsNull([MSGFDB_SpecProb], 0) AS [MSGFDB_SpecProb],
	   IsNull([MSGFDB_PValue], 0) AS [MSGFDB_PValue],
	   IsNull([MSGFPlus_QValue], 0) AS [MSGFPlus_QValue],
	   IsNull([MSGFPlus_PepQValue], 0) AS [MSGFPlus_PepQValue],
	   IsNull([MSAlign_PValue], 0) AS [MSAlign_PValue],
	   IsNull([MSAlign_FDR], 0) AS [MSAlign_FDR],
	   IsNull([Inspect_MQScore], 0) AS [Inspect_MQScore],
	   IsNull([Inspect_TotalPRMScore], 0) AS [Inspect_TotalPRMScore],
	   IsNull([Inspect_FScore], 0) AS [Inspect_FScore],
	   IsNull([Inspect_PValue], 0) AS [Inspect_PValue],
	   IsNull([Discriminant_Score], 0) AS [Discriminant_Score],
	   IsNull([NET_Difference_Absolute], 0) AS [NET_Difference_Absolute],
	   IsNull([Discriminant_Initial_Filter], 0) AS [Discriminant_Initial_Filter],
	   IsNull([Peptide_Length], 0) AS [Peptide_Length],
	   IsNull([Mass], 0) AS [Mass],
	   IsNull([Spectrum_Count], 0) AS [Spectrum_Count],
	   IsNull([Protein_Count], 0) AS [Protein_Count]
FROM ( SELECT Filter_Set_ID,
                   Filter_Set_Name,
                   Filter_Set_Description,
                   Filter_Criteria_Group_ID,
                   Criterion_Name,
                   Criterion_Value
       FROM V_Filter_Set_Criteria ) AS SourceTable
     PIVOT ( Max(Criterion_Value)
             FOR Criterion_Name
             IN ( [Spectrum_Count], [Charge], [High_Normalized_Score], [Cleavage_State], [Peptide_Length], 
	              [Mass], [DelCn], [DelCn2], [Discriminant_Score], [NET_Difference_Absolute], [Discriminant_Initial_Filter], [Protein_Count], [Terminus_State], 
	              [XTandem_Hyperscore], [XTandem_LogEValue], [Peptide_Prophet_Probability], [RankScore], 
	              [Inspect_MQScore], [Inspect_TotalPRMScore], [Inspect_FScore], [Inspect_PValue], 
	              [MSGF_SpecProb], [MSGFDB_SpecProb], [MSGFDB_PValue], [MSGFPlus_QValue], [MSGFPlus_PepQValue],
	              [MSAlign_PValue], [MSAlign_FDR] ) 
	       ) AS PivotData



GO
