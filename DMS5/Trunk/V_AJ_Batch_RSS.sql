/****** Object:  View [dbo].[V_AJ_Batch_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_AJ_Batch_RSS
AS
SELECT     'Batch ' + CONVERT(VARCHAR(12), Batch_ID) AS post_title, '' AS url_title, Jobs_Finished AS post_date, 
                      Batch_Description + ' (' + 'Total:' + CONVERT(VARCHAR(12), Total_Jobs) + ', Complete:' + CONVERT(VARCHAR(12), Completed_Jobs) 
                      + ', Failed:' + CONVERT(VARCHAR(12), Failed_Jobs) + ', Busy:' + CONVERT(VARCHAR(12), Busy_Jobs) + ')' AS post_body, Batch_Created
FROM         (SELECT     dbo.T_Analysis_Job_Batches.Batch_ID, dbo.T_Analysis_Job_Batches.Batch_Created, dbo.T_Analysis_Job_Batches.Batch_Description, 
                                              COUNT(dbo.T_Analysis_Job.AJ_jobID) AS Total_Jobs, SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (4, 14) THEN 1 ELSE 0 END) 
                                              AS Completed_Jobs, SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (5, 6, 7, 12, 15, 18, 99) THEN 1 ELSE 0 END) AS Failed_Jobs, 
                                              SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (2, 3, 8, 9, 10, 11, 16, 17) THEN 1 ELSE 0 END) AS Busy_Jobs, 
                                              MAX(dbo.T_Analysis_Job.AJ_finish) AS Jobs_Finished
                       FROM          dbo.T_Analysis_Job_Batches INNER JOIN
                                              dbo.T_Analysis_Job ON dbo.T_Analysis_Job_Batches.Batch_ID = dbo.T_Analysis_Job.AJ_batchID
                       GROUP BY dbo.T_Analysis_Job_Batches.Batch_Description, dbo.T_Analysis_Job_Batches.Batch_Created, 
                                              dbo.T_Analysis_Job_Batches.Batch_ID
                       HAVING      (MAX(dbo.T_Analysis_Job.AJ_finish) > DATEADD(DAY, - 30, GETDATE()))) AS T
WHERE     (Total_Jobs = Failed_Jobs + Completed_Jobs)

GO
GRANT VIEW DEFINITION ON [dbo].[V_AJ_Batch_RSS] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_AJ_Batch_RSS] TO [PNL\D3M580] AS [dbo]
GO
