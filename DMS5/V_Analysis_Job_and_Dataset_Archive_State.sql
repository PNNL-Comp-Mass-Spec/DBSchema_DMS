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
                DA.AS_state_ID IN (3, 4, 10, 14, 15) THEN ASN.AJS_name
           WHEN AJ.AJ_StateID = 1 AND
                DA.AS_state_ID < 3 THEN ASN.AJS_name + ' (Dataset Not Archived)'
           WHEN AJ.AJ_StateID = 1 AND
                DA.AS_state_ID > 3 THEN ASN.AJS_name + ' (Dataset ' + DASN.DASN_StateName + ')'
           ELSE ASN.AJS_name
       END AS Job_State,
       IsNull(DASN.DASN_StateName, '') AS Dataset_Archive_State
FROM dbo.T_DatasetArchiveStateName AS DASN
     INNER JOIN dbo.T_Dataset_Archive AS DA
       ON DASN.DASN_StateID = DA.AS_state_ID
     RIGHT OUTER JOIN dbo.T_Analysis_Job AS AJ
                      INNER JOIN dbo.T_Analysis_State_Name AS ASN
                        ON AJ.AJ_StateID = ASN.AJS_stateID
                      INNER JOIN dbo.T_Dataset AS D
                        ON AJ.AJ_datasetID = D.Dataset_ID
       ON DA.AS_Dataset_ID = D.Dataset_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_and_Dataset_Archive_State] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_and_Dataset_Archive_State] TO [PNL\D3M580] AS [dbo]
GO
