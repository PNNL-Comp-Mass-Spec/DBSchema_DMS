/****** Object:  View [dbo].[V_Analysis_Job_and_Dataset_Archive_State] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Analysis_Job_and_Dataset_Archive_State
AS
SELECT AJ.AJ_jobID AS Job, 
	CASE WHEN AJ.AJ_StateID = 1 AND DA.AS_update_state_ID = 3 THEN ASN.AJS_name + ' (Archive Update in Progress)'
	WHEN AJ.AJ_StateID = 1 AND DA.AS_state_ID IN (3, 4, 10) THEN ASN.AJS_name
	WHEN AJ.AJ_StateID = 1 AND DA.AS_state_ID < 3 THEN ASN.AJS_name + ' (Dataset Not Archived)'
    WHEN AJ.AJ_StateID = 1 AND DA.AS_state_ID > 3 THEN ASN.AJS_name + ' (Dataset ' + DASN.DASN_StateName + ')' 
	ELSE ASN.AJS_name 
	END AS Job_State, 
    DASN.DASN_StateName AS Dataset_Archive_State
FROM dbo.T_Analysis_Job AJ INNER JOIN
    dbo.T_Analysis_State_Name ASN ON 
    AJ.AJ_StateID = ASN.AJS_stateID INNER JOIN
    dbo.T_Dataset D ON 
    AJ.AJ_datasetID = D.Dataset_ID INNER JOIN
    dbo.T_Dataset_Archive DA ON 
    D.Dataset_ID = DA.AS_Dataset_ID INNER JOIN
    dbo.T_DatasetArchiveStateName DASN ON 
    DA.AS_state_ID = DASN.DASN_StateID

GO
