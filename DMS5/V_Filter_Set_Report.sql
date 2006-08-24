/****** Object:  View [dbo].[V_Filter_Set_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Filter_Set_Report
AS
SELECT TOP 100 PERCENT dbo.T_Filter_Set_Types.Filter_Type_Name,
     dbo.T_Filter_Sets.Filter_Set_ID, 
    dbo.T_Filter_Sets.Filter_Set_Name, 
    dbo.T_Filter_Sets.Filter_Set_Description, 
    FSG.Filter_Criteria_Group_ID, 
    QSpectrumCount.Criterion_Comparison AS Spectrum_Count_Comparison,
     QSpectrumCount.Criterion_Value AS Spectrum_Count_Value, 
    QCharge.Criterion_Comparison AS Charge_Comparison, 
    QCharge.Criterion_Value AS Charge_Value, 
    QScore.Criterion_Comparison AS Score_Comparison, 
    QScore.Criterion_Value AS Score_Value, 
    QCleavageState.Criterion_Comparison AS Cleavage_State_Comparison,
     QCleavageState.Criterion_Value AS Cleavage_State_Value, 
    QTerminusState.Criterion_Comparison AS Terminus_State_Comparison,
     QTerminusState.Criterion_Value AS Terminus_State_Value, 
    QPeptideLength.Criterion_Comparison AS Peptide_Length_Comparison,
     QPeptideLength.Criterion_Value AS Peptide_Length_Value, 
    QMass.Criterion_Comparison AS Mass_Comparison, 
    QMass.Criterion_Value AS Mass_Value, 
    QDelCn.Criterion_Comparison AS DelCn_Comparison, 
    QDelCn.Criterion_Value AS DelCn_Value, 
    QDelCn2.Criterion_Comparison AS DelCn2_Comparison, 
    QDelCn2.Criterion_Value AS DelCn2_Value, 
    QDiscriminantScore.Criterion_Comparison AS Discriminant_Score_Comparison,
     QDiscriminantScore.Criterion_Value AS Discriminant_Score_Value,
     QNETDifference.Criterion_Comparison AS NET_Difference_Comparison,
     QNETDifference.Criterion_Value AS NET_Difference_Value, 
    QDiscriminantInitialFilter.Criterion_Comparison AS Discriminant_Initial_Filter_Comparison,
     QDiscriminantInitialFilter.Criterion_Value AS Discriminant_Initial_Filter_Value,
     QProteinCount.Criterion_Comparison AS Protein_Count_Comparison,
     QProteinCount.Criterion_Value AS Protein_Count_Value
FROM dbo.T_Filter_Set_Types INNER JOIN
    dbo.T_Filter_Sets ON 
    dbo.T_Filter_Set_Types.Filter_Type_ID = dbo.T_Filter_Sets.Filter_Type_ID
     LEFT OUTER JOIN
    dbo.T_Filter_Set_Criteria_Groups FSG ON 
    dbo.T_Filter_Sets.Filter_Set_ID = FSG.Filter_Set_ID LEFT OUTER
     JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 1)) QSpectrumCount ON 
    FSG.Filter_Criteria_Group_ID = QSpectrumCount.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 2)) QCharge ON 
    FSG.Filter_Criteria_Group_ID = QCharge.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 3)) QScore ON 
    FSG.Filter_Criteria_Group_ID = QScore.Filter_Criteria_Group_ID LEFT
     OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 4)) QCleavageState ON 
    FSG.Filter_Criteria_Group_ID = QCleavageState.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 13)) QTerminusState ON 
    FSG.Filter_Criteria_Group_ID = QTerminusState.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 5)) QPeptideLength ON 
    FSG.Filter_Criteria_Group_ID = QPeptideLength.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 6)) QMass ON 
    FSG.Filter_Criteria_Group_ID = QMass.Filter_Criteria_Group_ID LEFT
     OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 7)) QDelCn ON 
    FSG.Filter_Criteria_Group_ID = QDelCn.Filter_Criteria_Group_ID LEFT
     OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 8)) QDelCn2 ON 
    FSG.Filter_Criteria_Group_ID = QDelCn2.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 9)) QDiscriminantScore ON 
    FSG.Filter_Criteria_Group_ID = QDiscriminantScore.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 10)) QNETDifference ON 
    FSG.Filter_Criteria_Group_ID = QNETDifference.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 11)) QDiscriminantInitialFilter ON 
    FSG.Filter_Criteria_Group_ID = QDiscriminantInitialFilter.Filter_Criteria_Group_ID
     LEFT OUTER JOIN
        (SELECT C.Filter_Set_Criteria_ID, C.Filter_Criteria_Group_ID, 
           N .Criterion_Name, C.Criterion_Comparison, 
           C.Criterion_Value
      FROM dbo.T_Filter_Set_Criteria AS C INNER JOIN
           dbo.T_Filter_Set_Criteria_Names AS N ON 
           C.Criterion_ID = N .Criterion_ID
      WHERE (C.Criterion_ID = 12)) QProteinCount ON 
    FSG.Filter_Criteria_Group_ID = QProteinCount.Filter_Criteria_Group_ID
ORDER BY dbo.T_Filter_Set_Types.Filter_Type_Name, 
    dbo.T_Filter_Sets.Filter_Set_ID, FSG.Filter_Criteria_Group_ID

GO
