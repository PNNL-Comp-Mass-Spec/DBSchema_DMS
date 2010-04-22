/****** Object:  StoredProcedure [dbo].[MakeNotificationDatasetEvents] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.MakeNotificationDatasetEvents
/****************************************************
**
**  Desc: 
**  Adds dataset notification events 
**  to notification event table
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 04/02/2010
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
	-- window for dataset activity
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
	-- 
	---------------------------------------------------
	--
	DECLARE @eventTypetID INT
	SET @eventTypetID = 20 -- 'Dataset Not Released'

	---------------------------------------------------
	-- temp table for events to be added
	---------------------------------------------------
	--
	CREATE TABLE #ENV (
		Target_ID INT,
		Event_Type int
	)

	INSERT INTO #ENV
		( Target_ID,
		  Event_Type 
		)
	SELECT
	  T_Dataset.Dataset_ID,
	  @eventTypetID
	FROM
	  T_Dataset
	WHERE
	  ( T_Dataset.DS_rating BETWEEN -5 AND -1 )
	AND 
	  T_Dataset.DS_created BETWEEN @window AND @now
		AND NOT EXISTS ( SELECT
						*
					   FROM
						dbo.T_Notification_Event AS TNE
					   WHERE
						TNE.Target_ID = T_Dataset.Dataset_ID
						AND TNE.Event_Type = @eventTypetID )
	  

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
		Event_Type = @eventTypetID
		AND Entered < @window
	

GO
