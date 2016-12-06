/****** Object:  View [dbo].[V_Requested_Run_Batch_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Requested_Run_Batch_RSS AS
SELECT     TS.ID AS url_title, CONVERT(VARCHAR(12), TS.ID) + ' - ' + TS.Batch AS post_title, TS.post_date, CONVERT(VARCHAR(12), TS.ID) 
                      + '_' + CONVERT(VARCHAR(12), TS.num) AS guid, TU.U_Name + '|' + TS.Description + '|' + CONVERT(VARCHAR(12), TS.num) + ' datasets' AS post_body, 
                      TU.U_PRN
FROM         (SELECT     TB.ID, TB.Batch, MAX(TD.DS_created) AS post_date, COUNT(TD.Dataset_ID) AS num, TB.Description, TB.Owner
                       FROM          T_Dataset AS TD INNER JOIN
                                              T_Requested_Run AS TH ON TD.Dataset_ID = TH.DatasetID INNER JOIN
                                              T_Requested_Run_Batches AS TB ON TH.RDS_BatchID = TB.ID
                       WHERE      (TB.ID <> 0) AND (NOT (TB.ID IN
                                                  (SELECT     RDS_BatchID
                                                    FROM          T_Requested_Run)))
                       GROUP BY TB.ID, TB.Batch, TB.Description, TB.Owner
                       HAVING      (MAX(TD.DS_created) > DATEADD(DAY, - 30, GETDATE()))) AS TS INNER JOIN
                      T_Users AS TU ON TS.Owner = TU.ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_RSS] TO [DDL_Viewer] AS [dbo]
GO
