/****** Object:  StoredProcedure [dbo].[UpdateCampaignTracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateCampaignTracking
/****************************************************
**
**	Desc: Updates cell culture tracking table with summary counts
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	
**
**		Auth: grk
**		Date: 10/20/2002
**    
*****************************************************/
AS
	declare @message varchar(512)

	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	-- clear results table
	--
	DELETE FROM T_Campaign_Tracking
	 
	-- make entry in results table for each cell culture
	--
	INSERT INTO T_Campaign_Tracking
						(C_ID)
	SELECT     Campaign_ID
	FROM         T_Campaign
	 
	-- update cell culture count statistics for results table
	--
	UPDATE T
	SET Cell_Culture_Count = S.Cnt
	FROM T_Campaign_Tracking as T inner join
	(
	SELECT     T_Campaign.Campaign_ID, COUNT(T_Cell_Culture.CC_ID) AS Cnt
	FROM         T_Campaign INNER JOIN
						T_Cell_Culture ON T_Campaign.Campaign_ID = T_Cell_Culture.CC_Campaign_ID
	GROUP BY T_Campaign.Campaign_ID	
	) as S on T.C_ID = S.Campaign_ID
	 
	-- update experiment count statistics for results table
	--
	UPDATE T
	SET Experiment_Count = S.Cnt
	FROM T_Campaign_Tracking as T inner join
	(
	SELECT     T_Campaign.Campaign_ID, COUNT(T_Experiments.Exp_ID) AS cnt
	FROM         T_Campaign INNER JOIN
						T_Experiments ON T_Campaign.Campaign_ID = T_Experiments.EX_campaign_ID
	GROUP BY T_Campaign.Campaign_ID
	) as S on T.C_ID = S.Campaign_ID


	-- update dataset count statistics for results table
	--
	UPDATE T
	SET Dataset_Count = S.Cnt
	FROM T_Campaign_Tracking as T inner join
	(
	SELECT     T_Campaign.Campaign_ID, COUNT(T_Dataset.Dataset_ID) AS Cnt
	FROM         T_Experiments INNER JOIN
						T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID INNER JOIN
						T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
	GROUP BY T_Campaign.Campaign_ID
	)
	as S on T.C_ID = S.Campaign_ID 

	-- update analysis count statistics for results table
	--
	UPDATE T
	SET Job_Count = S.Cnt
	FROM T_Campaign_Tracking as T inner join
	(
	SELECT     T_Campaign.Campaign_ID, COUNT(T_Analysis_Job.AJ_jobID) AS Cnt
	FROM         T_Experiments INNER JOIN
						T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID INNER JOIN
						T_Analysis_Job ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID INNER JOIN
						T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
	GROUP BY T_Campaign.Campaign_ID
	) as S on T.C_ID = S.Campaign_ID 

	RETURN @myError


 
GO
