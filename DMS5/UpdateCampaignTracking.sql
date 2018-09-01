/****** Object:  StoredProcedure [dbo].[UpdateCampaignTracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCampaignTracking]
/****************************************************
**
**  Desc: Updates cell culture tracking table with summary counts
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/20/2002
**          11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**          01/18/2010 grk - added update for run requests and sample prep requests (http://prismtrac.pnl.gov/trac/ticket/753)
**          01/25/2010 grk - added 'most recent activity' (http://prismtrac.pnl.gov/trac/ticket/753)
**          04/15/2015 mem - Added Data_Package_Count
**          08/29/2018 mem - Added Sample_Submission_Count and Sample_Submission_Most_Recent
**          08/30/2018 mem - Use merge instead of truncate
**    
*****************************************************/
AS
    Declare @message varchar(512)

    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    set @message = ''

    ----------------------------------------------------------
    -- Create a temporary table to hold the stats
    ----------------------------------------------------------
    --
    CREATE TABLE #Tmp_CampaignStats (
	    Campaign_ID int NOT NULL,
	    Sample_Submission_Count int NOT NULL,
	    Cell_Culture_Count int NOT NULL,
	    Experiment_Count int NOT NULL,
	    Dataset_Count int NOT NULL,
	    Job_Count int NOT NULL,
	    Run_Request_Count int NOT NULL,
	    Sample_Prep_Request_Count int NOT NULL,
	    Data_Package_Count int NOT NULL,
	    Sample_Submission_Most_Recent datetime NULL,
	    Cell_Culture_Most_Recent datetime NULL,
	    Experiment_Most_Recent datetime NULL,
	    Dataset_Most_Recent datetime NULL,
	    Job_Most_Recent datetime NULL,
	    Run_Request_Most_Recent datetime NULL,
	    Sample_Prep_Request_Most_Recent datetime NULL,
	    Most_Recent_Activity datetime NULL,
        CONSTRAINT PK_Tmp_CampaignStats PRIMARY KEY CLUSTERED (Campaign_ID ASC)
    ) 
     
    ----------------------------------------------------------
    -- Make entry in results table for each campaign
    ----------------------------------------------------------
    --
    INSERT INTO #Tmp_CampaignStats( Campaign_ID,
                                    Most_Recent_Activity,
                                    Sample_Submission_Count,
                                    Cell_Culture_Count,
                                    Experiment_Count,
                                    Dataset_Count,
                                    Job_Count,
                                    Run_Request_Count,
                                    Sample_Prep_Request_Count,
                                    Data_Package_Count )
    SELECT Campaign_ID,
           CM_created AS Most_Recent_Activity,
           0, 0, 0, 0, 0, 0, 0, 0
    FROM T_Campaign
    --
	SELECT @myError = @@error, @myRowCount = @@rowcount

    ----------------------------------------------------------
    -- Update sample submission statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Sample_Submission_Count = S.Cnt,
        Sample_Submission_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Campaign.Campaign_ID,
                             COUNT(T_Sample_Submission.ID) AS Cnt,
                             MAX(T_Sample_Submission.Created) AS Most_Recent
                      FROM T_Campaign
                           INNER JOIN T_Sample_Submission
                             ON T_Campaign.Campaign_ID = T_Sample_Submission.Campaign_ID
                      GROUP BY T_Campaign.Campaign_ID ) AS S
           ON #Tmp_CampaignStats.Campaign_ID = S.Campaign_ID

    ----------------------------------------------------------
    -- Update cell culture statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Cell_Culture_Count = S.Cnt,
        Cell_Culture_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Campaign.Campaign_ID,
                             COUNT(T_Cell_Culture.CC_ID) AS Cnt,
                             MAX(T_Cell_Culture.CC_Created) AS Most_Recent
                      FROM T_Campaign
                           INNER JOIN T_Cell_Culture
                             ON T_Campaign.Campaign_ID = T_Cell_Culture.CC_Campaign_ID
                      GROUP BY T_Campaign.Campaign_ID ) AS S
           ON #Tmp_CampaignStats.Campaign_ID = S.Campaign_ID

    ----------------------------------------------------------
    -- Update experiment statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Experiment_Count = S.Cnt,
        Experiment_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Campaign.Campaign_ID,
                             COUNT(T_Experiments.Exp_ID) AS cnt,
                             MAX(T_Experiments.EX_created) AS Most_Recent
                      FROM T_Campaign
                           INNER JOIN T_Experiments
                             ON T_Campaign.Campaign_ID = T_Experiments.EX_campaign_ID
                      GROUP BY T_Campaign.Campaign_ID ) AS S
           ON #Tmp_CampaignStats.Campaign_ID = S.Campaign_ID

    ----------------------------------------------------------
    -- Update dataset statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Dataset_Count = S.Cnt,
        Dataset_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Campaign.Campaign_ID,
                             COUNT(T_Dataset.Dataset_ID) AS Cnt,
                             MAX(T_Dataset.DS_created) AS Most_Recent
                      FROM T_Experiments
                           INNER JOIN T_Dataset
                             ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
                           INNER JOIN T_Campaign
                             ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
                      GROUP BY T_Campaign.Campaign_ID ) AS S
           ON #Tmp_CampaignStats.Campaign_ID = S.Campaign_ID

    ----------------------------------------------------------
    -- Update analysis statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Job_Count = S.Cnt,
        Job_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Campaign.Campaign_ID,
                             COUNT(T_Analysis_Job.AJ_jobID) AS Cnt,
                             MAX(T_Analysis_Job.AJ_created) AS Most_Recent
                      FROM T_Experiments
                           INNER JOIN T_Dataset
                             ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
                           INNER JOIN T_Analysis_Job
                             ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
                           INNER JOIN T_Campaign
                             ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
                      GROUP BY T_Campaign.Campaign_ID ) AS S
           ON #Tmp_CampaignStats.Campaign_ID = S.Campaign_ID

    ----------------------------------------------------------
    -- Update requested run statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Run_Request_Count = S.cnt,
        Run_Request_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Experiments.EX_campaign_ID AS ID,
                             COUNT(T_Requested_Run.ID) AS cnt,
                             MAX(T_Requested_Run.RDS_created) AS Most_Recent
                      FROM T_Requested_Run
                           INNER JOIN T_Experiments
                             ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID
                      GROUP BY T_Experiments.EX_campaign_ID ) AS S
           ON S.ID = #Tmp_CampaignStats.Campaign_ID


    ----------------------------------------------------------
    -- Update sample prep statistics
    ----------------------------------------------------------
    --
    UPDATE #Tmp_CampaignStats
    SET Sample_Prep_Request_Count = S.cnt,
        Sample_Prep_Request_Most_Recent = S.Most_Recent,
        Most_Recent_Activity = CASE
                                   WHEN S.Most_Recent > Most_Recent_Activity THEN S.Most_Recent
                                   ELSE Most_Recent_Activity
                               END
    FROM #Tmp_CampaignStats
         INNER JOIN ( SELECT T_Campaign.Campaign_ID AS ID,
                             COUNT(T_Sample_Prep_Request.ID) AS cnt,
                             MAX(T_Sample_Prep_Request.Created) AS Most_Recent
                      FROM T_Sample_Prep_Request
                           INNER JOIN T_Campaign
                             ON T_Sample_Prep_Request.Campaign = T_Campaign.Campaign_Num
                      GROUP BY T_Campaign.Campaign_ID ) AS S
           ON S.ID = #Tmp_CampaignStats.Campaign_ID

    ----------------------------------------------------------
    -- Update Data Package counts
    ----------------------------------------------------------
    --
    UPDATE T_Campaign_Tracking
    SET Data_Package_Count = S.cnt
    FROM T_Campaign_Tracking
         INNER JOIN ( SELECT E.EX_campaign_ID ID,
                             Count(DISTINCT Data_Package_ID) AS cnt
                      FROM S_V_Data_Package_Experiments_Export DPE
                           INNER JOIN T_Experiments E
                             ON E.Exp_ID = DPE.Experiment_ID
                      GROUP BY E.EX_campaign_ID ) AS S
           ON S.ID = T_Campaign_Tracking.C_ID


    ----------------------------------------------------------
    -- Update T_Campaign_Tracking using #Tmp_CampaignStats
    ----------------------------------------------------------
    --        
    MERGE T_Campaign_Tracking AS T
    USING (SELECT * FROM #Tmp_CampaignStats) as s
    ON ( t.C_ID = s.Campaign_ID)
    WHEN MATCHED AND (
        t.Cell_Culture_Count <> s.Cell_Culture_Count OR
        t.Experiment_Count <> s.Experiment_Count OR
        t.Dataset_Count <> s.Dataset_Count OR
        t.Job_Count <> s.Job_Count OR
        t.Run_Request_Count <> s.Run_Request_Count OR
        t.Sample_Prep_Request_Count <> s.Sample_Prep_Request_Count OR
        ISNULL( NULLIF(t.Sample_Submission_Count, s.Sample_Submission_Count),
                NULLIF(s.Sample_Submission_Count, t.Sample_Submission_Count)) IS NOT NULL OR
        ISNULL( NULLIF(t.Data_Package_Count, s.Data_Package_Count),
                NULLIF(s.Data_Package_Count, t.Data_Package_Count)) IS NOT NULL OR
        ISNULL( NULLIF(t.Sample_Submission_Most_Recent, s.Sample_Submission_Most_Recent),
                NULLIF(s.Sample_Submission_Most_Recent, t.Sample_Submission_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Cell_Culture_Most_Recent, s.Cell_Culture_Most_Recent),
                NULLIF(s.Cell_Culture_Most_Recent, t.Cell_Culture_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Experiment_Most_Recent, s.Experiment_Most_Recent),
                NULLIF(s.Experiment_Most_Recent, t.Experiment_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Dataset_Most_Recent, s.Dataset_Most_Recent),
                NULLIF(s.Dataset_Most_Recent, t.Dataset_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Job_Most_Recent, s.Job_Most_Recent),
                NULLIF(s.Job_Most_Recent, t.Job_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Run_Request_Most_Recent, s.Run_Request_Most_Recent),
                NULLIF(s.Run_Request_Most_Recent, t.Run_Request_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Sample_Prep_Request_Most_Recent, s.Sample_Prep_Request_Most_Recent),
                NULLIF(s.Sample_Prep_Request_Most_Recent, t.Sample_Prep_Request_Most_Recent)) IS NOT NULL OR
        ISNULL( NULLIF(t.Most_Recent_Activity, s.Most_Recent_Activity),
                NULLIF(s.Most_Recent_Activity, t.Most_Recent_Activity)) IS NOT NULL
        )
    THEN UPDATE SET 
        Sample_Submission_Count = s.Sample_Submission_Count,
        Cell_Culture_Count = s.Cell_Culture_Count,
        Experiment_Count = s.Experiment_Count,
        Dataset_Count = s.Dataset_Count,
        Job_Count = s.Job_Count,
        Run_Request_Count = s.Run_Request_Count,
        Sample_Prep_Request_Count = s.Sample_Prep_Request_Count,
        Data_Package_Count = s.Data_Package_Count,
        Sample_Submission_Most_Recent = s.Sample_Submission_Most_Recent,
        Cell_Culture_Most_Recent = s.Cell_Culture_Most_Recent,
        Experiment_Most_Recent = s.Experiment_Most_Recent,
        Dataset_Most_Recent = s.Dataset_Most_Recent,
        Job_Most_Recent = s.Job_Most_Recent,
        Run_Request_Most_Recent = s.Run_Request_Most_Recent,
        Sample_Prep_Request_Most_Recent = s.Sample_Prep_Request_Most_Recent,
        Most_Recent_Activity = s.Most_Recent_Activity
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(C_ID, Sample_Submission_Count, Cell_Culture_Count, Experiment_Count, Dataset_Count, Job_Count, Run_Request_Count, Sample_Prep_Request_Count, Data_Package_Count, Sample_Submission_Most_Recent, Cell_Culture_Most_Recent, Experiment_Most_Recent, Dataset_Most_Recent, Job_Most_Recent, Run_Request_Most_Recent, Sample_Prep_Request_Most_Recent, Most_Recent_Activity)
        VALUES(s.Campaign_ID, s.Sample_Submission_Count, s.Cell_Culture_Count, s.Experiment_Count, s.Dataset_Count, s.Job_Count, s.Run_Request_Count, s.Sample_Prep_Request_Count, s.Data_Package_Count, s.Sample_Submission_Most_Recent, s.Cell_Culture_Most_Recent, s.Experiment_Most_Recent, s.Dataset_Most_Recent, s.Job_Most_Recent, s.Run_Request_Most_Recent, s.Sample_Prep_Request_Most_Recent, s.Most_Recent_Activity)
    WHEN NOT MATCHED BY SOURCE THEN DELETE;

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCampaignTracking] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCampaignTracking] TO [Limited_Table_Write] AS [dbo]
GO
