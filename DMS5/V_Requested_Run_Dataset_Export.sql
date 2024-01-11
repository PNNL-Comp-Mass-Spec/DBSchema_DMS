/****** Object:  View [dbo].[V_Requested_Run_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Requested_Run_Dataset_Export]
AS
-- MyEMSL uses this view
SELECT RR.ID AS Request_ID,
       RR.RDS_Name AS Request_Name,
       RR.RDS_Status AS Status,
       RR.RDS_Origin AS Origin,
       RR.RDS_comment AS Request_Comment,
       RR.RDS_created AS Request_Created,
       RR.RDS_BatchID AS Batch,
       RR.RDS_instrument_group AS Requested_Inst_Group,
       RR.RDS_WorkPackage AS Work_Package,
       U.U_Name AS Requester,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       DS.Dataset_ID AS Dataset_ID,
       DS.DS_Comment AS Dataset_Comment,
       ISNULL(DS.Acq_Time_Start, RR.RDS_Run_Start) AS Acq_Start,
       InstName.IN_name AS Instrument,
       InstName.IN_Group As Instrument_Group,
       DS.DS_sec_sep As Separation_Type,
       RR.RDS_Sec_Sep AS Separation_Group,
       LC.Cart_Name AS Cart,
       DTN.DST_name AS Dataset_Type,
       EUT.Name AS EUS_Usage,
       RR.RDS_EUS_Proposal_ID,
       EPT.Abbreviation AS EUS_Proposal_Type,
       RR.Updated As Updated,
       U.U_Name AS Requestor        -- Legacy name
FROM T_Requested_Run AS RR
     INNER JOIN T_Dataset_Type_Name AS DTN
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users AS U
       ON RR.RDS_Requestor_PRN = U.U_PRN
     INNER JOIN T_Experiments AS E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     INNER JOIN T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_LC_Cart AS LC
       ON RR.RDS_Cart_ID = LC.ID
     INNER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     INNER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     LEFT OUTER JOIN T_EUS_Proposals AS EUP
       ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
     LEFT OUTER JOIN T_EUS_Proposal_Type EPT
       ON EUP.Proposal_Type = EPT.Proposal_Type

GO
