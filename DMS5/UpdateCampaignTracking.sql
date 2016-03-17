/****** Object:  StoredProcedure [dbo].[UpdateCampaignTracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateCampaignTracking
/****************************************************
**
**	Desc: Updates cell culture tracking table with summary counts
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	
**
**	Auth:	grk
**	Date:	10/20/2002
**			11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**			01/18/2010 grk - added update for run requests and sample prep requests (http://prismtrac.pnl.gov/trac/ticket/753)
**			01/25/2010 grk - added 'most recent activity' (http://prismtrac.pnl.gov/trac/ticket/753)
**			04/15/2015 mem - Added Data_Package_Count
**    
*****************************************************/
AS
	declare @message varchar(512)

	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	-- clear results table
	--
	TRUNCATE TABLE T_Campaign_Tracking
	 
	-- make entry in results table for each cell culture
	--
	INSERT INTO T_Campaign_Tracking ( 
		C_ID,
		Most_Recent_Activity
	)
	SELECT
		Campaign_ID,
		CM_created AS Most_Recent_Activity
	FROM
		T_Campaign
	 
	-- update cell culture count statistics for results table
	--
	UPDATE T
	SET
		Cell_Culture_Count = S.Cnt,
		Cell_Culture_Most_Recent = S.most_recent,
		Most_Recent_Activity = CASE WHEN S.most_recent > Most_Recent_Activity THEN S.most_recent ELSE Most_Recent_Activity END
	FROM
		T_Campaign_Tracking AS T
	INNER JOIN (
		SELECT
			T_Campaign.Campaign_ID,
			COUNT(T_Cell_Culture.CC_ID) AS Cnt,
			MAX(T_Cell_Culture.CC_Created) AS most_recent
		FROM
			T_Campaign
			INNER JOIN T_Cell_Culture ON T_Campaign.Campaign_ID = T_Cell_Culture.CC_Campaign_ID
		GROUP BY
			T_Campaign.Campaign_ID
	) AS S ON T.C_ID = S.Campaign_ID
	 
	-- update experiment count statistics for results table
	--
	UPDATE T
	SET
		Experiment_Count = S.Cnt,
		Experiment_Most_Recent = S.most_recent,
		Most_Recent_Activity = CASE WHEN S.most_recent > Most_Recent_Activity THEN S.most_recent ELSE Most_Recent_Activity END
	FROM
		T_Campaign_Tracking AS T
	INNER JOIN ( 
		SELECT
			T_Campaign.Campaign_ID,
			COUNT(T_Experiments.Exp_ID) AS cnt,
			MAX(T_Experiments.EX_created) AS most_recent
		FROM
			T_Campaign
			INNER JOIN T_Experiments ON T_Campaign.Campaign_ID = T_Experiments.EX_campaign_ID
		GROUP BY
			T_Campaign.Campaign_ID
	) AS S ON T.C_ID = S.Campaign_ID


	-- update dataset count statistics for results table
	--
	UPDATE T
	SET
		Dataset_Count = S.Cnt,
		Dataset_Most_Recent = S.most_recent,
		Most_Recent_Activity = CASE WHEN S.most_recent > Most_Recent_Activity THEN S.most_recent ELSE Most_Recent_Activity END
	FROM
		T_Campaign_Tracking AS T
	INNER JOIN ( 
		SELECT
			T_Campaign.Campaign_ID,
			COUNT(T_Dataset.Dataset_ID) AS Cnt,
			MAX(T_Dataset.DS_created) AS most_recent
		FROM
			T_Experiments
			INNER JOIN T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
			INNER JOIN T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
		GROUP BY
			T_Campaign.Campaign_ID
	) AS S ON T.C_ID = S.Campaign_ID 

	-- update analysis count statistics for results table
	--
	UPDATE T
	SET 
		Job_Count = S.Cnt,
		Job_Most_Recent = S.most_recent,
		Most_Recent_Activity = CASE WHEN S.most_recent > Most_Recent_Activity THEN S.most_recent ELSE Most_Recent_Activity END
	FROM 
		T_Campaign_Tracking as T inner join
	(
		SELECT
			T_Campaign.Campaign_ID,
			COUNT(T_Analysis_Job.AJ_jobID) AS Cnt,
			MAX(T_Analysis_Job.AJ_created) AS most_recent
		FROM
			T_Experiments
			INNER JOIN T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
			INNER JOIN T_Analysis_Job ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
			INNER JOIN T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
		GROUP BY
			T_Campaign.Campaign_ID
	) as S on T.C_ID = S.Campaign_ID 


	-- update requested run count statistics for results table
	--
	UPDATE
	  T_Campaign_Tracking
	SET
	  Run_Request_Count = S.cnt,
	  Run_Request_Most_Recent = S.most_recent,
		Most_Recent_Activity = CASE WHEN S.most_recent > Most_Recent_Activity THEN S.most_recent ELSE Most_Recent_Activity END
	FROM
	  T_Campaign_Tracking
	  INNER JOIN ( 
		SELECT
			T_Experiments.EX_campaign_ID AS ID,
			COUNT(T_Requested_Run.ID) AS cnt,
			MAX(T_Requested_Run.RDS_created) AS most_recent
		FROM
			T_Requested_Run
			INNER JOIN T_Experiments ON T_Requested_Run.Exp_ID = T_Experiments.Exp_ID
		GROUP BY
			T_Experiments.EX_campaign_ID

	) AS S ON S.ID = T_Campaign_Tracking.C_ID


	-- update sample prep count statistics for results table
	--
	UPDATE
	  T_Campaign_Tracking
	SET
	  Sample_Prep_Request_Count = S.cnt,
	  Sample_Prep_Request_Most_Recent = S.most_recent,
		Most_Recent_Activity = CASE WHEN S.most_recent > Most_Recent_Activity THEN S.most_recent ELSE Most_Recent_Activity END
	FROM
	  T_Campaign_Tracking
	  INNER JOIN ( 
		SELECT
			T_Campaign.Campaign_ID AS ID,
			COUNT(T_Sample_Prep_Request.ID) AS cnt,
			MAX(T_Sample_Prep_Request.Created) AS most_recent
		FROM
			T_Sample_Prep_Request
			INNER JOIN T_Campaign ON T_Sample_Prep_Request.Campaign = T_Campaign.Campaign_Num
		GROUP BY
			T_Campaign.Campaign_ID
	) AS S ON S.ID = T_Campaign_Tracking.C_ID

	-- Update Data Package counts
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

	
	RETURN @myError



GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCampaignTracking] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCampaignTracking] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCampaignTracking] TO [PNL\D3M580] AS [dbo]
GO
