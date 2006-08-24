/****** Object:  View [dbo].[V_Requested_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Requested_Run_Entry
AS
SELECT     T_Experiments.Experiment_Num AS RR_Experiment, T_Requested_Run.RDS_Name AS RR_Name, 
                      T_Requested_Run.RDS_instrument_name AS RR_Instrument, T_Requested_Run.RDS_comment AS RR_Comment, 
                      T_DatasetTypeName.DST_name AS RR_Type, T_Requested_Run.RDS_Oper_PRN AS RR_Requestor, 
                      T_Requested_Run.RDS_instrument_setting AS RR_Instrument_Settings, T_Requested_Run.RDS_special_instructions AS RR_Special_Instructions, 
                      T_Requested_Run.RDS_WorkPackage AS RR_WorkPackage, T_Requested_Run.ID AS RR_Request, 
                      T_Requested_Run.RDS_Well_Plate_Num AS RR_Wellplate_Num, T_Requested_Run.RDS_Well_Num AS RR_Well_Num, 
                      T_Requested_Run.RDS_internal_standard AS RR_Internal_Standard, T_Requested_Run.RDS_EUS_Proposal_ID AS RR_EUSProposalID, 
                      T_EUS_UsageType.Name AS RR_EUSUsageType, dbo.GetRequestedRunEUSUsersList(T_Requested_Run.ID, 'I') AS RR_EUSUsers
FROM         T_DatasetTypeName INNER JOIN
                      T_Requested_Run INNER JOIN
                      T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID ON 
                      T_DatasetTypeName.DST_Type_ID = T_Requested_Run.RDS_type_ID INNER JOIN
                      T_EUS_UsageType ON T_Requested_Run.RDS_EUS_UsageType = T_EUS_UsageType.ID

GO
