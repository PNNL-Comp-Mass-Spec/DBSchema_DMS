/****** Object:  View [dbo].[V_Requested_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Entry]
AS
SELECT RR.ID AS request_id,
       RR.RDS_Name AS request_name,
       E.Experiment_Num AS experiment,
       RR.RDS_instrument_group AS instrument_group,
       DTN.DST_Name AS dataset_type,
       RR.RDS_Sec_Sep AS separation_group,
       RR.RDS_Requestor_PRN AS requester_username,
       RR.RDS_instrument_setting AS instrument_settings,
       RR.RDS_Well_Plate_Num AS wellplate,
       RR.RDS_Well_Num AS well,
       RR.vialing_conc,
       RR.vialing_vol,
       RR.RDS_comment AS comment,
       ML.Tag AS staging_location,
       RR.RDS_BatchID AS batch_id,
       RR.RDS_Block AS [block],
       RR.RDS_Run_Order AS run_order,
       RR.RDS_WorkPackage AS work_package,
       EUT.Name AS eus_usage_type,
       RR.RDS_EUS_Proposal_ID AS eus_proposal_id,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS eus_users,
       ISNULL(dbo.T_Attachments.Attachment_Name, '') AS mrm_attachment,
       RR.RDS_internal_standard AS internal_standard,
       RR.RDS_Status AS state_name
FROM T_Requested_Run AS RR
     INNER JOIN T_DatasetTypeName AS DTN
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN dbo.T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     LEFT OUTER JOIN dbo.T_Attachments
       ON RR.RDS_MRM_Attachment = dbo.T_Attachments.ID
     LEFT OUTER JOIN T_Material_Locations ML
       ON RR.Location_ID = ML.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Entry] TO [DDL_Viewer] AS [dbo]
GO
