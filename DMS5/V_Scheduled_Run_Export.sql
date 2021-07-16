/****** Object:  View [dbo].[V_Scheduled_Run_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Scheduled_Run_Export]
AS
-- This view was superseded by V_Requested_Run_Active_Export in January 2021
-- This view was updated in July 2021 to report adjusted Request IDs due to a bug in older versions of LCMS Net that could not handle request IDs over 999999
SELECT RR.ID - 800000 AS Request,       -- Adjusted Request ID
       RR.RDS_Name AS Name,
       RR.RDS_priority AS Priority,
       RR.RDS_instrument_group AS Instrument,
       DTN.DST_name AS [Type],
       E.Experiment_Num AS Experiment,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_comment AS [Comment],
       RR.RDS_note AS Note,
       RR.RDS_WorkPackage AS [Work Package],
       RR.RDS_Well_Plate_Num AS [Wellplate Number],
       RR.RDS_Well_Num AS [Well Number],
       RR.RDS_internal_standard AS [Internal Standard],
       RR.RDS_instrument_setting AS [Instrument Settings],
       RR.RDS_special_instructions AS [Special Instructions],
       LC.Cart_Name AS Cart,
       RR.RDS_Run_Start AS [Run Start],
       RR.RDS_Run_Finish AS [Run Finish],
       EUT.Name AS [Usage Type],
       RRCU.User_List AS [EUS Users],
       RR.RDS_EUS_Proposal_ID AS [Proposal ID],
       RR.RDS_MRM_Attachment AS MRMFileID,
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS RunOrder,
       RR.RDS_BatchID AS Batch,
       RR.Vialing_Conc,
       RR.Vialing_Vol,
       RR.ID As RequestID               -- Actual Request ID
FROM T_DatasetTypeName DTN
     INNER JOIN T_Requested_Run RR
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users U
       ON RR.RDS_Requestor_PRN = U.U_PRN
     INNER JOIN T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_LC_Cart LC
       ON RR.RDS_Cart_ID = LC.ID
     INNER JOIN T_EUS_UsageType EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     LEFT OUTER JOIN T_Active_Requested_Run_Cached_EUS_Users RRCU
       ON RR.ID = RRCU.Request_ID
WHERE (RR.RDS_Status = 'Active')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Scheduled_Run_Export] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Scheduled_Run_Export] TO [DMS_LCMSNet_User] AS [dbo]
GO
