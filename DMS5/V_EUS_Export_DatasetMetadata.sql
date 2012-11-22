/****** Object:  View [dbo].[V_EUS_Export_DatasetMetadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_EUS_Export_DatasetMetadata
AS
SELECT D.Dataset_ID AS Dataset_ID,
       D.Dataset_Num AS Dataset,
       Inst.IN_name AS Instrument,
       DTN.DST_name AS Dataset_Type,
       U_DS_Operator.U_Name AS Instrument_Operator,
       DRN.DRN_name AS Dataset_Rating,
       E.Experiment_Num AS Experiment,
       O.OG_name AS Organism,
       E.EX_reason AS Experiment_Reason,
       E.EX_comment AS Experiment_Comment,
       U_Ex_Researcher.U_Name AS Experiment_Researcher,
       SPR.ID AS Prep_Request_ID,
       SPR.Assigned_Personnel AS Prep_Request_Staff,
       C.Campaign_Num AS Campaign,
       ISNULL(U_ProjMgr.U_Name, C.CM_Proj_Mgr_PRN) AS Project_Manager,
       ISNULL(U_PI.U_Name, C.CM_PI_PRN) AS Project_PI,
       ISNULL(U_TechLead.U_Name, C.CM_Technical_Lead) AS Project_Technical_Lead,
       D.DS_Oper_PRN AS Instrument_Operator_PRN,
       E.EX_researcher_PRN AS Experiment_Researcher_PRN
FROM T_Campaign C
     INNER JOIN T_Dataset D
                INNER JOIN T_Instrument_Name Inst
                  ON D.DS_instrument_name_ID = Inst.Instrument_ID
                INNER JOIN T_DatasetTypeName DTN
                  ON D.DS_type_ID = DTN.DST_Type_ID
                INNER JOIN T_Users U_DS_Operator
                  ON D.DS_Oper_PRN = U_DS_Operator.U_PRN
                INNER JOIN T_DatasetRatingName DRN
                  ON D.DS_rating = DRN.DRN_state_ID
                INNER JOIN T_Experiments E
                  ON D.Exp_ID = E.Exp_ID
                INNER JOIN T_Users U_Ex_Researcher
                  ON E.EX_researcher_PRN = U_Ex_Researcher.U_PRN
                INNER JOIN T_Organisms O
                  ON E.EX_organism_ID = O.Organism_ID
       ON C.Campaign_ID = E.EX_campaign_ID
     LEFT OUTER JOIN T_Users U_TechLead
       ON C.CM_Technical_Lead = U_TechLead.U_PRN
     LEFT OUTER JOIN T_Users U_PI
       ON C.CM_PI_PRN = U_PI.U_PRN
     LEFT OUTER JOIN T_Users U_ProjMgr
       ON C.CM_Proj_Mgr_PRN = U_ProjMgr.U_PRN
     LEFT OUTER JOIN T_Sample_Prep_Request SPR
       ON E.EX_sample_prep_request_ID = SPR.ID AND
          SPR.ID <> 0
WHERE D.DS_State_ID=3 AND D.DS_Rating NOT IN (-1, -2, -5)

GO
