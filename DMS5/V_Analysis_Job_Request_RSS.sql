/****** Object:  View [dbo].[V_Analysis_Job_Request_RSS] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_RSS]
AS
SELECT 'Request ' + CONVERT(varchar(12), AJR_requestID) + ' - ' + AJR_requestName AS post_title,
       AJR_requestID AS url_title,
       Jobs_Finished AS post_date,
       AJR_requestName + '|' + Requester + '|' + 
       ' (' + 'Total:' +    CONVERT(varchar(12), Total_Jobs) + ', '+ 
              'Complete:' + CONVERT(varchar(12), Completed_Jobs) + ', ' + 
              'Failed:' +   CONVERT(varchar(12), Failed_Jobs) + ', ' + 
              'Busy:' +     CONVERT(varchar(12), Busy_Jobs) + ')' AS post_body,
       CONVERT(varchar(12), AJR_requestID) + '-' + CONVERT(varchar(12), Total_Jobs) + '-' + CONVERT(varchar(12), Completed_Jobs) AS guid
FROM ( SELECT T_Analysis_Job_Request.AJR_requestID,
              T_Analysis_Job_Request.AJR_requestName,
              COUNT(T_Analysis_Job.AJ_jobID) AS Total_Jobs,
              SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (4, 14) THEN 1 ELSE 0 END)                      AS Completed_Jobs,
              SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (5, 6, 7, 12, 15, 18, 99) THEN 1 ELSE 0 END)    AS Failed_Jobs,
              SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN (2, 3, 8, 9, 10, 11, 16, 17) THEN 1 ELSE 0 END) AS Busy_Jobs,
              MAX(T_Analysis_Job.AJ_finish) AS Jobs_Finished,
              T_Users.U_Name AS Requester,
              T_Users.U_PRN
       FROM T_Analysis_Job
            INNER JOIN T_Analysis_Job_Request
              ON T_Analysis_Job.AJ_requestID = T_Analysis_Job_Request.AJR_requestID
            INNER JOIN T_Users
              ON T_Analysis_Job_Request.AJR_requestor = T_Users.ID
       GROUP BY T_Analysis_Job_Request.AJR_requestName
                , T_Analysis_Job_Request.AJR_requestID, T_Users.U_Name,
                T_Analysis_Job_Request.AJR_state, T_Users.U_PRN
       HAVING (MAX(T_Analysis_Job.AJ_finish) > DATEADD(DAY, -30, GETDATE())) AND
              T_Analysis_Job_Request.AJR_requestID > 1 
     ) AS LookupQ
WHERE Total_Jobs = Failed_Jobs + Completed_Jobs


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_RSS] TO [DDL_Viewer] AS [dbo]
GO
