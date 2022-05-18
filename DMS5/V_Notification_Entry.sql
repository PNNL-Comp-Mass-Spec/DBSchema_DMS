/****** Object:  View [dbo].[V_Notification_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Notification_Entry]
AS
SELECT prn,
       name,
       CASE WHEN R1 > 0 THEN 'Yes' ELSE 'No' END AS requested_run_batch,
       CASE WHEN R2 > 0 THEN 'Yes' ELSE 'No' END AS analysis_job_request,
       CASE WHEN R3 > 0 THEN 'Yes' ELSE 'No' END AS sample_prep_request,
       CASE WHEN R4 > 0 THEN 'Yes' ELSE 'No' END AS dataset_not_released,
       CASE WHEN R5 > 0 THEN 'Yes' ELSE 'No' END AS dataset_released
FROM ( SELECT TU.U_PRN AS PRN,
              TU.U_Name AS Name,
              MAX(CASE
                      WHEN ISNULL(TNEU.Entity_Type_ID, 0) = 1 THEN 1
                      ELSE 0
                  END) AS R1,
              MAX(CASE
                      WHEN ISNULL(TNEU.Entity_Type_ID, 0) = 2 THEN 1
                      ELSE 0
                  END) AS R2,
              MAX(CASE
                      WHEN ISNULL(TNEU.Entity_Type_ID, 0) = 3 THEN 1
                      ELSE 0
                  END) AS R3,
              MAX(CASE
                      WHEN ISNULL(TNEU.Entity_Type_ID, 0) = 4 THEN 1
                      ELSE 0
                  END) AS R4,
              MAX(CASE
                      WHEN ISNULL(TNEU.Entity_Type_ID, 0) = 5 THEN 1
                      ELSE 0
                  END) AS R5
    FROM T_Notification_Entity_User AS TNEU
        RIGHT OUTER JOIN T_Users TU
          ON TNEU.User_ID = TU.ID
    GROUP BY TU.U_PRN, TU.U_Name ) T


GO
GRANT VIEW DEFINITION ON [dbo].[V_Notification_Entry] TO [DDL_Viewer] AS [dbo]
GO
