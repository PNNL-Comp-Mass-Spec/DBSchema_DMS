/****** Object:  View [dbo].[V_Requested_Run_Fraction_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Fraction_Entry]
AS
SELECT RR.ID AS source_request_id,
       RR.RDS_Name AS source_request_name,
       E.Experiment_Num AS experiment,
       RR.RDS_instrument_group AS instrument_group,
       DTN.DST_Name AS run_type,
       RR.RDS_Sec_Sep AS source_separation_group,
       '' AS separation_group,
       RR.RDS_Requestor_PRN AS requester,
       RR.RDS_instrument_setting AS instrument_settings,
       ML.Tag AS staging_location,
       RR.RDS_Well_Plate_Num AS wellplate,
       RR.RDS_Well_Num AS well,
       RR.Vialing_Conc AS vialing_concentration,
       RR.Vialing_Vol AS vialing_volume,
       RR.RDS_comment AS comment,
       RR.RDS_WorkPackage AS work_package,
       EUT.Name AS eus_usage_type,
       RR.RDS_EUS_Proposal_ID AS eus_proposal_id,
       dbo.get_requested_run_eus_users_list(RR.ID, 'I') AS eus_user,
       ISNULL(dbo.T_Attachments.Attachment_Name, '') AS mrm_attachment
FROM T_Requested_Run AS RR
     INNER JOIN T_Dataset_Type_Name AS DTN
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
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Fraction_Entry] TO [DDL_Viewer] AS [dbo]
GO
