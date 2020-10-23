/****** Object:  View [dbo].[V_Requested_Run_Fraction_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Fraction_Entry]
AS
SELECT RR.ID AS Source_Request_ID,
       RR.RDS_Name AS Source_Request_Name,
       E.Experiment_Num AS Experiment,
       RR.RDS_instrument_group AS Instrument_Group,
       DTN.DST_Name AS Run_Type,
       RR.RDS_Sec_Sep AS Source_Separation_Group,
       '' AS Separation_Group,
       RR.RDS_Requestor_PRN AS Requestor,
       RR.RDS_instrument_setting AS Instrument_Settings,
       ML.Tag AS Staging_Location,
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       RR.Vialing_Conc AS Vialing_Concentration,
       RR.Vialing_Vol AS Vialing_Volume,
       RR.RDS_comment AS [Comment],
       RR.RDS_WorkPackage AS Work_Package,
       EUT.Name AS EUS_Usage_Type,
       RR.RDS_EUS_Proposal_ID AS EUS_Proposal_ID,
       dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS EUS_User,
       ISNULL(dbo.T_Attachments.Attachment_Name, '') AS MRM_Attachment
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
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Fraction_Entry] TO [DDL_Viewer] AS [dbo]
GO
