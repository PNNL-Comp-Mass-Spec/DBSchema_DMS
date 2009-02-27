/****** Object:  View [dbo].[V_Analysis_Job_Request_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Request_RSS
AS
SELECT     'Request ' + CONVERT(VARCHAR(12), AJR_requestID) + ' - ' + AJR_requestName AS post_title, AJR_requestID AS url_title, Jobs_Finished AS post_date, 
                      AJR_requestName + '|' + Requester + '|' + ' (' + 'Total:' + CONVERT(VARCHAR(12), Total_Jobs) + ', Complete:' + CONVERT(VARCHAR(12), 
                      Completed_Jobs) + ', Failed:' + CONVERT(VARCHAR(12), Failed_Jobs) + ', Busy:' + CONVERT(VARCHAR(12), Busy_Jobs) + ')' AS post_body, 
                      CONVERT(VARCHAR(12), AJR_requestID) + '-' + CONVERT(VARCHAR(12), Total_Jobs) + '-' + CONVERT(VARCHAR(12), Completed_Jobs) AS guid
FROM         (SELECT     dbo.T_Analysis_Job_Request.AJR_requestID, dbo.T_Analysis_Job_Request.AJR_requestName, COUNT(dbo.T_Analysis_Job.AJ_jobID) 
                                              AS Total_Jobs, SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (4, 14) THEN 1 ELSE 0 END) AS Completed_Jobs, 
                                              SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (5, 6, 7, 12, 15, 18, 99) THEN 1 ELSE 0 END) AS Failed_Jobs, 
                                              SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (2, 3, 8, 9, 10, 11, 16, 17) THEN 1 ELSE 0 END) AS Busy_Jobs, 
                                              MAX(dbo.T_Analysis_Job.AJ_finish) AS Jobs_Finished, dbo.T_Users.U_Name AS Requester, dbo.T_Users.U_PRN
                       FROM          dbo.T_Analysis_Job INNER JOIN
                                              dbo.T_Analysis_Job_Request ON dbo.T_Analysis_Job.AJ_requestID = dbo.T_Analysis_Job_Request.AJR_requestID INNER JOIN
                                              dbo.T_Users ON dbo.T_Analysis_Job_Request.AJR_requestor = dbo.T_Users.ID
                       GROUP BY dbo.T_Analysis_Job_Request.AJR_requestName, dbo.T_Analysis_Job_Request.AJR_requestID, dbo.T_Users.U_Name, 
                                              dbo.T_Analysis_Job_Request.AJR_state, dbo.T_Users.U_PRN
                       HAVING      (MAX(dbo.T_Analysis_Job.AJ_finish) > DATEADD(DAY, -30, GETDATE()))) AS T
WHERE     (Total_Jobs = Failed_Jobs + Completed_Jobs)

GO
