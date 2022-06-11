/****** Object:  View [dbo].[V_Campaign_List_Stale] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Campaign_List_Stale]
AS
SELECT C.Campaign_ID,
       C.Campaign_Num As Campaign,
       C.CM_State As State,
       CT.Most_Recent_Activity,
       CT.Sample_Prep_Request_Most_Recent as most_recent_sample_prep_request,
       CT.Experiment_Most_Recent as most_recent_experiment,
       CT.Run_Request_Most_Recent as most_recent_run_request,
       CT.Dataset_Most_Recent as most_recent_dataset,
       CT.Job_Most_Recent as most_recent_analysis_job,
       C.CM_created As Created
   FROM T_Campaign C
     LEFT JOIN T_Campaign_Tracking CT ON CT.C_ID = C.Campaign_ID
WHERE COALESCE(CT.sample_prep_request_most_recent, '1/1/2000') <= DATEADD(MONTH, -18, GETDATE()) AND
      COALESCE(CT.experiment_most_recent, '1/1/2000') <= DATEADD(MONTH, -18, GETDATE()) AND
      COALESCE(CT.run_request_most_recent, '1/1/2000') <= DATEADD(MONTH, -18, GETDATE()) AND
      COALESCE(CT.dataset_most_recent, '1/1/2000') <= DATEADD(MONTH, -18, GETDATE()) AND
      COALESCE(CT.job_most_recent, '1/1/2000') <= DATEADD(MONTH, -18, GETDATE()) AND
      C.CM_created < DATEADD(year, -7, GETDATE())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_List_Stale] TO [DDL_Viewer] AS [dbo]
GO
