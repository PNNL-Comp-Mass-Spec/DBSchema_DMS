/****** Object:  View [dbo].[V_Requested_Run_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Helper_List_Report]
AS
SELECT RR.ID AS request,
       RR.RDS_Name AS name,
       RR.RDS_BatchID As batch,
       E.Experiment_Num AS experiment,
       RR.RDS_instrument_group AS instrument,
       U.U_Name AS requester,
       RR.RDS_created AS created,
       RR.RDS_WorkPackage AS work_package,
       RR.RDS_comment AS comment,
       DTN.DST_name AS type,
       RR.RDS_Well_Plate_Num AS wellplate,
       RR.RDS_Well_Num AS well
FROM T_Dataset_Type_Name DTN
     INNER JOIN T_Requested_Run RR
       ON DTN.DST_Type_ID = RR.RDS_type_ID
     INNER JOIN T_Users U
       ON RR.RDS_Requestor_PRN = U.U_PRN
     INNER JOIN T_Experiments E
       ON RR.Exp_ID = E.Exp_ID
WHERE RR.DatasetID Is Null

GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Helper_List_Report] TO [DDL_Viewer] AS [dbo]
GO
