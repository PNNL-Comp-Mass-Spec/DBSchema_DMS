/****** Object:  View [dbo].[V_Requested_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Requested_Run_Entry
AS
SELECT     dbo.T_Experiments.Experiment_Num AS RR_Experiment, dbo.T_Requested_Run.RDS_Name AS RR_Name, 
                      dbo.T_Requested_Run.RDS_instrument_name AS RR_Instrument, dbo.T_Requested_Run.RDS_comment AS RR_Comment, 
                      dbo.T_DatasetTypeName.DST_Name AS RR_Type, dbo.T_Requested_Run.RDS_Oper_PRN AS RR_Requestor, 
                      dbo.T_Requested_Run.RDS_instrument_setting AS RR_Instrument_Settings, 
                      dbo.T_Requested_Run.RDS_special_instructions AS RR_Special_Instructions, dbo.T_Requested_Run.RDS_WorkPackage AS RR_WorkPackage, 
                      dbo.T_Requested_Run.ID AS RR_Request, dbo.T_Requested_Run.RDS_Well_Plate_Num AS RR_Wellplate_Num, 
                      dbo.T_Requested_Run.RDS_Well_Num AS RR_Well_Num, dbo.T_Requested_Run.RDS_internal_standard AS RR_Internal_Standard, 
                      dbo.T_Requested_Run.RDS_EUS_Proposal_ID AS RR_EUSProposalID, dbo.T_EUS_UsageType.Name AS RR_EUSUsageType, 
                      dbo.GetRequestedRunEUSUsersList(dbo.T_Requested_Run.ID, 'I') AS RR_EUSUsers, dbo.T_Requested_Run.RDS_Sec_Sep AS RR_SecSep, 
                      ISNULL(dbo.T_Attachments.Attachment_Name, '') AS MRMAttachment, dbo.T_Requested_Run.RDS_Status AS RR_Status
FROM         dbo.T_DatasetTypeName INNER JOIN
                      dbo.T_Requested_Run INNER JOIN
                      dbo.T_Experiments ON dbo.T_Requested_Run.Exp_ID = dbo.T_Experiments.Exp_ID ON 
                      dbo.T_DatasetTypeName.DST_Type_ID = dbo.T_Requested_Run.RDS_type_ID INNER JOIN
                      dbo.T_EUS_UsageType ON dbo.T_Requested_Run.RDS_EUS_UsageType = dbo.T_EUS_UsageType.ID LEFT OUTER JOIN
                      dbo.T_Attachments ON dbo.T_Requested_Run.RDS_MRM_Attachment = dbo.T_Attachments.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Entry] TO [PNL\D3M580] AS [dbo]
GO
