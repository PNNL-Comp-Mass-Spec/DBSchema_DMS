/****** Object:  View [dbo].[V_Filter_Set_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Filter_Set_Report]
AS
SELECT FST.Filter_Type_Name,
       FS.Filter_Set_ID,
       FS.Filter_Set_Name,
       FS.Filter_Set_Description,
       FSCG.Filter_Criteria_Group_ID,
       PR.[2]  AS Charge,
       PR.[3]  AS High_Normalized_Score,
       PR.[4]  AS Cleavage_State,
       PR.[13] AS Terminus_State,
       PR.[7]  AS DelCn,
       PR.[8]  AS DelCn2,
       PR.[17] AS RankScore,
       PR.[14] AS XTandem_Hyperscore,
       PR.[15] AS XTandem_LogEValue,
       PR.[16] AS Peptide_Prophet_Probability,
       PR.[22] AS MSGF_SpecProb,
       PR.[23] AS MSGFDB_SpecProb,
       PR.[24] AS MSGFDB_PValue,
       PR.[25] AS MSGFPlus_QValue,		-- previously named MSGFDB_FDR
       PR.[28] AS MSGFPlus_PepQValue,
       PR.[26] AS MSAlign_PValue,
       PR.[27] AS MSAlign_FDR,
       PR.[18] AS Inspect_MQScore,
       PR.[19] AS Inspect_TotalPRMScore,
       PR.[20] AS Inspect_FScore,
       PR.[21] AS Inspect_PValue,
       PR.[9]  AS Discriminant_Score,
       PR.[10] AS NET_Difference_Absolute,
       PR.[11] AS Discriminant_Initial_Filter,
       PR.[5]  AS Peptide_Length,
       PR.[6]  AS Mass,
       PR.[1]  AS Spectrum_Count,
       PR.[12] AS Protein_Count
FROM ( SELECT FSC.Filter_Criteria_Group_ID,
              Criterion_id,
              Criterion_Comparison + CONVERT(varchar(18), Criterion_Value) AS Criterion
       FROM dbo.T_Filter_Set_Criteria FSC ) AS DataQ
     PIVOT ( MAX(Criterion)
             FOR Criterion_id
             IN ( [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12], [13], [14], [15], [16], [17], [18], [19], [20], [21], [22], [23], [24], [25], [26], [27], [28] ) 
     ) AS PR
     INNER JOIN dbo.T_Filter_Set_Criteria_Groups FSCG
       ON PR.Filter_Criteria_Group_ID = FSCG.Filter_Criteria_Group_ID
     INNER JOIN dbo.T_Filter_Sets FS
       ON FSCG.Filter_Set_ID = FS.Filter_Set_ID
     INNER JOIN dbo.T_Filter_Set_Types FST
       ON FS.Filter_Type_ID = FST.Filter_Type_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Filter_Set_Report] TO [PNL\D3M578] AS [dbo]
GO
