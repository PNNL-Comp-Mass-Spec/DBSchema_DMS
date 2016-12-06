/****** Object:  StoredProcedure [dbo].[MakeNotificationAnalysisJobRequestEvents] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.MakeNotificationAnalysisJobRequestEvents
/****************************************************
**
**  Desc: 
**  Adds analysis job request notification events 
**  to notification event table
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/30/2010
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
  
	---------------------------------------------------
	-- window for analysis job activity
	---------------------------------------------------
	--
	DECLARE @window DATETIME 
	SET @window = DATEADD(DAY, -7, GETDATE())

	---------------------------------------------------
	-- window for batch creation date
	---------------------------------------------------
	--
	DECLARE @threshold DATETIME
	SET @threshold = DATEADD(DAY, -90, GETDATE())

	---------------------------------------------------
	-- earlier than batch creation window 
	-- (default for datasets with null start time)
	---------------------------------------------------
	--
	DECLARE @now datetime
	SET  @now = GETDATE()
	--
	DECLARE @past DATETIME 
	SET @past = '1/1/2000'
	--
	DECLARE @future DATETIME 
	SET @future = DATEADD(MONTH, 3, @now)

	---------------------------------------------------
	-- temp table for analysis job requests of interest
	---------------------------------------------------
	--
	CREATE TABLE #BAT (
		ID INT,
		Total_Jobs INT,
		Completed_Jobs INT NULL,
		Earliest_Job_Start DATETIME NULL,
		Latest_Job_Finish DATETIME NULL
	)

	---------------------------------------------------
	--
	---------------------------------------------------
	--
	 INSERT INTO #BAT
		( ID,
		  Total_Jobs,
		  Completed_Jobs,
		  Earliest_Job_Start,
		  Latest_Job_Finish
		)
	SELECT
	  T_Analysis_Job_Request.AJR_requestID AS ID,
	  COUNT(T_Analysis_Job.AJ_jobID) AS Total_Jobs,
	  SUM(CASE WHEN T_Analysis_Job.AJ_StateID IN ( 4, 14 ) THEN 1
			   ELSE 0
		  END) AS Completed_Jobs,
	  MIN(ISNULL(T_Analysis_Job.AJ_start, @future)) AS Earliest_Job_Start,
	  MAX(ISNULL(T_Analysis_Job.AJ_finish, @past)) AS Latest_Job_Finish
	FROM
	  T_Analysis_Job
	  INNER JOIN T_Analysis_Job_Request ON T_Analysis_Job.AJ_requestID = T_Analysis_Job_Request.AJR_requestID
	WHERE
	  ( T_Analysis_Job_Request.AJR_requestID > 1 )
	  AND ( T_Analysis_Job_Request.AJR_created > @threshold)
	GROUP BY
	  T_Analysis_Job_Request.AJR_requestID
	  
	  
/*
SELECT
  CONVERT(VARCHAR(15), ID) AS ID,
  CONVERT(VARCHAR(15), Total_Jobs) AS Total_Jobs,
  CONVERT(VARCHAR(15), Completed_Jobs) AS Completed_Jobs,
  CONVERT(VARCHAR(15), Earliest_Job_Start) AS Earliest_Job_Start,
  CONVERT(VARCHAR(15), Latest_Job_Finish) AS Latest_Job_Finish
FROM
  #BAT
*/  

	---------------------------------------------------
	-- temp table for events to be added
	---------------------------------------------------
	--
	CREATE TABLE #ENV (
		Target_ID INT,
		Event_Type int
	)

	---------------------------------------------------
	-- 4, 'Analysis Job Request Start', 2 )
	---------------------------------------------------
	DECLARE @eventType INT
	SET @eventType = 4
	--
	INSERT INTO #ENV
	(Target_ID, Event_Type)
	SELECT 
		ID,
		@eventType 
	FROM 
		#BAT
	WHERE 
		Earliest_Job_Start between @window AND @now
		AND NOT EXISTS 
		(
			SELECT * 
			FROM T_Notification_Event TNE 
			WHERE TNE.Target_ID = #BAT.ID AND TNE.Event_Type = @eventType
		)

	---------------------------------------------------
	-- 5, 'Analysis Job Request Finish', 2 )
	---------------------------------------------------
	--
	SET @eventType = 5
	--
	INSERT INTO #ENV
	(Target_ID, Event_Type)
	SELECT 
		ID,
		@eventType 
	FROM 
		#BAT
	WHERE 
		Total_Jobs = Completed_Jobs
		AND Latest_Job_Finish between @window AND @now
		AND NOT EXISTS 
		(
			SELECT * 
			FROM T_Notification_Event TNE 
			WHERE TNE.Target_ID = #BAT.ID AND TNE.Event_Type = @eventType
		)

/*
SELECT * FROM #ENV
*/
	---------------------------------------------------
	-- add new events to table
	---------------------------------------------------
	--
	 INSERT INTO dbo.T_Notification_Event
			( Event_Type,
			  Target_ID
			)
	SELECT
	  #ENV.Event_Type,
	  #ENV.Target_ID
	FROM
	  #ENV
	WHERE
	  NOT EXISTS ( SELECT
					*
				   FROM
					T_Notification_Event TNE
				   WHERE
					TNE.Target_ID = #ENV.Target_ID
					AND TNE.Event_Type = #ENV.Event_Type )
					
	---------------------------------------------------
	-- clean out batch events older than window
	---------------------------------------------------
	--
	DELETE FROM
		T_Notification_Event
	WHERE
		Event_Type IN ( 4,5 )
		AND Entered < @window
	

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationAnalysisJobRequestEvents] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationAnalysisJobRequestEvents] TO [Limited_Table_Write] AS [dbo]
GO
