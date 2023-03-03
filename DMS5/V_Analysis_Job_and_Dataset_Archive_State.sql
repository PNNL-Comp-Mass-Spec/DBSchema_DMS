/****** Object:  View [dbo].[V_Analysis_Job_and_Dataset_Archive_State] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_and_Dataset_Archive_State]
AS
SELECT AJ.AJ_jobID AS Job,
       CASE
           WHEN AJ.AJ_StateID = 1 AND
                (DA.AS_state_ID IN (3, 4, 10, 14, 15) OR
				 DA.AS_state_Last_Affected < DateAdd(minute, -180, GetDate())) THEN ASN.AJS_name
           WHEN AJ.AJ_StateID = 1 AND
                DA.AS_state_ID < 3 THEN ASN.AJS_name + ' (Dataset Not Archived)'
           WHEN AJ.AJ_StateID = 1 AND
                DA.AS_state_ID > 3 THEN ASN.AJS_name + ' (Dataset ' + DASN.archive_state + ')'
           ELSE ASN.AJS_name
       END AS Job_State,
       IsNull(DASN.archive_state, '') AS Dataset_Archive_State,
       AJ.AJ_datasetID As Dataset_ID
FROM T_Analysis_Job AS AJ
     INNER JOIN T_Analysis_State_Name AS ASN
       ON AJ.AJ_StateID = ASN.AJS_stateID
     INNER JOIN T_Dataset AS D
       ON AJ.AJ_datasetID = D.Dataset_ID
     LEFT OUTER JOIN T_Dataset_Archive DA
       On DA.AS_Dataset_ID = AJ.AJ_datasetID
     LEFT OUTER JOIN T_Dataset_Archive_State_Name AS DASN
       On  DASN.archive_state_id = DA.AS_state_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_and_Dataset_Archive_State] TO [DDL_Viewer] AS [dbo]
GO
