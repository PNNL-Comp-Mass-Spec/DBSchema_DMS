/****** Object:  StoredProcedure [dbo].[MakeNotificationRequestedRunBatchEvents] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.MakeNotificationRequestedRunBatchEvents
/****************************************************
**
**  Desc: Adds new or edits existing T_Bogus
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 03/26/2010
**			 03/30/2010 grk - added intermediate table
**			04/01/2010 grk - added Latest_Suspect_Dataset
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
	-- window for requested run activity
	---------------------------------------------------
	--
	DECLARE @window DATETIME 
	SET @window = DATEADD(DAY, -7, GETDATE())

	---------------------------------------------------
	-- window for batch creation date
	---------------------------------------------------
	--
	DECLARE @threshold DATETIME
	SET @threshold = DATEADD(DAY, -365, GETDATE())

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
	-- temp table for batches of interest
	-- (batches created within epoc with datasets present)
	---------------------------------------------------
	--
	CREATE TABLE #BAT (
		ID INT,
		Num_Requests INT,
		Num_Datasets INT NULL,
		Num_Datasets_With_Start_Time INT NULL,
		Earliest_Dataset DATETIME NULL,
		Latest_Dataset DATETIME NULL,
		Latest_Suspect_Dataset DATETIME NULL
	)

	---------------------------------------------------
	--
	---------------------------------------------------
	--
	INSERT INTO #BAT
	( 
		ID,
		Num_Requests,
		Num_Datasets,
		Num_Datasets_With_Start_Time,
		Earliest_Dataset,
		Latest_Dataset,
		Latest_Suspect_Dataset
	)
	SELECT
		TB.ID,
		COUNT(*) AS Num_Requests,
		SUM(CASE WHEN TD.Dataset_ID IS NULL THEN 0
			   ELSE 1
		  END) AS Num_Datasets,
		SUM(CASE WHEN TD.Acq_Time_Start IS NULL THEN 0
			   ELSE 1
		  END) AS Num_Datasets_With_Start_Time,
		MIN(ISNULL(TD.DS_created, @future)) AS Earliest_Dataset,
		MAX(ISNULL(TD.DS_created, @past)) AS Latest_Dataset,
		MAX(CASE WHEN TD.DS_rating BETWEEN -5 AND -1 THEN TD.DS_created
			   ELSE @past
		  END) AS Latest_Suspect_Dataset
	FROM
		T_Requested_Run_Batches AS TB
		INNER JOIN T_Requested_Run AS TH ON TH.RDS_BatchID = TB.ID
		LEFT OUTER JOIN T_Dataset AS TD ON TD.Dataset_ID = TH.DatasetID
	WHERE
		( TB.ID <> 0 )
		AND ( TB.Created > @threshold )
	GROUP BY
		TB.ID 
/*
SELECT
		CONVERT(VARCHAR(22), #BAT.ID) AS Batch,
		CONVERT(VARCHAR(22), #BAT.Num_Requests) AS Num_Requests,
		CONVERT(VARCHAR(22), #BAT.Num_Datasets) AS Num_Datasets,
--		CONVERT(VARCHAR(22), #BAT.Num_Datasets_With_Start_Time) AS Num_Datasets_With_Start_Time,
		CONVERT(VARCHAR(22), #BAT.Earliest_Dataset) AS Earliest_Dataset,
		CONVERT(VARCHAR(22), #BAT.Latest_Dataset) AS Latest_Dataset,
		CONVERT(VARCHAR(22), #BAT.Latest_Suspect_Dataset) AS Latest_Suspect_Dataset,
		CONVERT(VARCHAR(22), T_Notification_Event.Event_Type) AS Event_Type
FROM
  #BAT
  LEFT OUTER JOIN dbo.T_Notification_Event ON #BAT.ID = dbo.T_Notification_Event.Target_ID
WHERE Num_Requests > Num_Datasets AND Num_Datasets > 0
ORDER BY #BAT.ID
RETURN
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
	-- event 'Requested Run Batch Start'
	--- Num_Datasets > 0
	--- Earliest_Dataset within window
	--- 'Requested Run Batch Start' event and TB.ID not already in event table
	---------------------------------------------------
	DECLARE @eventType INT
	SET @eventType = 1
	--
	INSERT INTO #ENV
	(Target_ID, Event_Type)
	SELECT 
		ID,
		@eventType 
	FROM 
		#BAT
	WHERE 
		Num_Datasets > 0
		AND Earliest_Dataset between @window AND @now
		AND NOT EXISTS 
		(
			SELECT * 
			FROM T_Notification_Event TNE 
			WHERE TNE.Target_ID = #BAT.ID AND TNE.Event_Type = @eventType
		)

	---------------------------------------------------
	-- event 'Requested Run Batch Finish'
	--- Num_Requests = Num_Datasets
	--- Latest_Dataset within window
	--- 'Requested Run Batch Finish' event and TB.ID not already in event table
	---------------------------------------------------
	--
	SET @eventType = 2
	--
	INSERT INTO #ENV
	(Target_ID, Event_Type)
	SELECT 
		ID,
		@eventType 
	FROM 
		#BAT
	WHERE 
		Num_Datasets = Num_Requests
		AND Latest_Dataset between @window AND @now
		AND NOT EXISTS 
		(
			SELECT * 
			FROM T_Notification_Event TNE 
			WHERE TNE.Target_ID = #BAT.ID AND TNE.Event_Type = @eventType
		)

	---------------------------------------------------
	-- event 'Requested Run Batch Acq Time Ready'
	--- Num_Requests = Num_Datasets_With_Start_Time
	--- Latest_Dataset within window
	--- 'Requested Run Batch Acq Time Ready' event and TB.ID not already in event table
	---------------------------------------------------
	--
	SET @eventType = 3
	--
	INSERT INTO #ENV
	(Target_ID, Event_Type)
	SELECT 
		ID,
		@eventType 
	FROM 
		#BAT
	WHERE 
		Num_Requests = Num_Datasets_With_Start_Time
		AND Latest_Dataset between @window AND @now
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
		Event_Type IN ( 1, 2, 3 )
		AND Entered < @window
	

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationRequestedRunBatchEvents] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationRequestedRunBatchEvents] TO [PNL\D3M578] AS [dbo]
GO
