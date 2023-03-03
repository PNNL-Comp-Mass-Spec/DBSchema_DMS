/****** Object:  View [dbo].[V_Requested_Run_Active_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Active_Export]
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_priority AS Priority,
       RR.RDS_instrument_group AS Instrument,
       DTN.DST_name AS [Type],
       E.Experiment_Num AS Experiment,
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       RR.RDS_comment AS [Comment],
       RR.RDS_note AS Note,
       RR.RDS_WorkPackage AS [Work Package],            -- Deprecated in July 2022
       RR.RDS_WorkPackage AS Work_Package,
       RR.RDS_Well_Plate_Num AS [Wellplate Number],     -- Deprecated in July 2022
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS [Well Number],                -- Deprecated in July 2022
       RR.RDS_Well_Num AS Well,
       RR.RDS_internal_standard AS [Internal Standard], -- Deprecated in July 2022
       RR.RDS_internal_standard AS Internal_Standard,
       RR.RDS_instrument_setting AS [Instrument Settings],      -- Deprecated in July 2022
       RR.RDS_instrument_setting AS Instrument_Settings,
       RR.RDS_special_instructions AS [Special Instructions],   -- Deprecated in July 2022
       RR.RDS_special_instructions AS Special_Instructions,
       LC.Cart_Name AS Cart,
       RR.RDS_Run_Start AS [Run Start],                 -- Deprecated in July 2022
       RR.RDS_Run_Start AS Run_Start,
       RR.RDS_Run_Finish AS [Run Finish],               -- Deprecated in July 2022
       RR.RDS_Run_Finish AS Run_Finish,
       EUT.Name AS [Usage Type],                        -- Deprecated in July 2022
       EUT.Name AS Usage_Type,
       RRCU.User_List AS [EUS Users],                   -- Deprecated in July 2022
       RRCU.User_List AS EUS_Users,
       RR.RDS_EUS_Proposal_ID AS [Proposal ID],         -- Deprecated in July 2022
       RR.RDS_EUS_Proposal_ID AS Proposal_ID,
       RR.RDS_MRM_Attachment AS MRMFileID,              -- Deprecated in July 2022
       RR.RDS_MRM_Attachment AS MRM_File_ID,
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS RunOrder,                    -- Deprecated in July 2022
       RR.RDS_Run_Order AS Run_Order,
       RR.RDS_BatchID AS Batch,
       RR.Vialing_Conc,
       RR.Vialing_Vol
FROM T_Dataset_Type_Name DTN
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
