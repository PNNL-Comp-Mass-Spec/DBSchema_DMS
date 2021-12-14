/****** Object:  View [dbo].[V_Requested_Run_Helper_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_Helper_List_Report]
AS
SELECT RR.ID AS Request,
       RR.RDS_Name AS Name,
       RR.RDS_BatchID As Batch,
       E.Experiment_Num AS Experiment,
       RR.RDS_instrument_group AS Instrument,
       U.U_Name AS Requestor,
       RR.RDS_created AS Created,
       RR.RDS_WorkPackage AS [Work Package],
       RR.RDS_comment AS Comment_____________,
       DTN.DST_name AS [Type],
       RR.RDS_Well_Plate_Num AS Wellplate,
       RR.RDS_Well_Num AS Well
FROM T_DatasetTypeName DTN
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
