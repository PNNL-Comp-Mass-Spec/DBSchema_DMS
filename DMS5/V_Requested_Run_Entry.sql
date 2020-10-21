/****** Object:  View [dbo].[V_Requested_Run_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Entry]
AS
SELECT RR.ID AS RR_Request,
       RR.RDS_Name AS RR_Name,
       E.Experiment_Num AS RR_Experiment,
       RR.RDS_instrument_group AS RR_Instrument,
       DTN.DST_Name AS RR_Type,
       RR.RDS_Sec_Sep AS RR_SecSep,
       RR.RDS_Requestor_PRN AS RR_Requestor,
       RR.RDS_instrument_setting AS RR_Instrument_Settings,
       RR.RDS_Well_Plate_Num AS RR_Wellplate_Num,
       RR.RDS_Well_Num AS RR_Well_Num,
       RR.Vialing_Conc AS RR_VialingConc,
       RR.Vialing_Vol AS RR_VialingVol,
       RR.RDS_comment AS RR_Comment,
       ML.Tag AS StagingLocation,
       RR.RDS_WorkPackage AS RR_WorkPackage,
       EUT.Name AS RR_EUSUsageType,
       RR.RDS_EUS_Proposal_ID AS RR_EUSProposalID,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS RR_EUSUsers,
       ISNULL(dbo.T_Attachments.Attachment_Name, '') AS MRMAttachment,
       RR.RDS_internal_standard AS RR_Internal_Standard,
       RR.RDS_Status AS RR_Status
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
