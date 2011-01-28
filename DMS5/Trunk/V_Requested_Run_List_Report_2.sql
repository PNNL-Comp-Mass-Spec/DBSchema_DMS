/****** Object:  View [dbo].[V_Requested_Run_List_Report_2] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_List_Report_2]
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_Status AS [Status],
       RR.RDS_Origin AS Origin,
       RR.RDS_priority AS Pri,
       RR.RDS_BatchID AS Batch,
       C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       DS.Dataset_Num AS Dataset,
       ISNULL(InstName.IN_name, '') AS Instrument,       
       RR.RDS_instrument_name AS [Inst. Group],
       U.U_Name AS Requester,
       RR.RDS_created AS Created,
       QT.[Days In Queue],
       RR.RDS_WorkPackage AS [Work Package],
       EUT.Name AS [Usage],
       RR.RDS_EUS_Proposal_ID AS Proposal,
       RR.RDS_comment AS [Comment],
       RR.RDS_note AS Note,
       DTN.DST_name AS [Type],
       RR.RDS_Sec_Sep AS [Separation Type],
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well,
       RR.RDS_Block AS [Block],
       RR.RDS_Run_Order AS [Run Order],
       LC.Cart_Name AS Cart,
       CONVERT(varchar(12), RR.RDS_Cart_Col) AS Col,
       RR.RDS_NameCode AS [Request Name Code],
       CASE 
            WHEN RR.RDS_Status <> 'Active' THEN 0   -- Request is not active
			WHEN QT.[Days In Queue] <= 30 THEN	30	-- Request is 0 to 30 days old
			WHEN QT.[Days In Queue] <= 60 THEN	60	-- Request is 30 to 60 days old
			WHEN QT.[Days In Queue] <= 90 THEN	90	-- Request is 60 to 90 days old
			ELSE 120								-- Request is over 90 days old
		END AS [#DaysInQueue]
FROM T_Requested_Run AS RR
     INNER JOIN T_DatasetTypeName AS DTN
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users AS U
       ON RR.RDS_Oper_PRN = U.U_PRN
     INNER JOIN T_Experiments AS E
       ON RR.Exp_ID = E.Exp_ID
     INNER JOIN T_EUS_UsageType AS EUT
       ON RR.RDS_EUS_UsageType = EUT.ID
     INNER JOIN T_Campaign AS C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_LC_Cart LC
       ON RR.RDS_Cart_ID = LC.ID
     LEFT OUTER JOIN T_Dataset AS DS
       ON RR.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     LEFT OUTER JOIN V_Requested_Run_Queue_Times AS QT
       ON RR.ID = QT.RequestedRun_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_List_Report_2] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_List_Report_2] TO [PNL\D3M580] AS [dbo]
GO
