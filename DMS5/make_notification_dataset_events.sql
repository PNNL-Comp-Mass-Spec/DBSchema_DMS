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
**  Auth:	grk
**  Date:	04/02/2010 grk - Initial Release
**			04/02/2010 mem - Updated the "Not Released" check to cover Dataset Rating -9 to 1
**                         - Now also looking for "Released" datasets
**			11/03/2016 mem - Fix bug that was failing to remove events of type 20 (Dataset Not Released) from T_Notification_Event
**    
*****************************************************/
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- window for dataset activity
	---------------------------------------------------
	--
	DECLARE @window DATETIME = DATEADD(DAY, -7, GETDATE())

	---------------------------------------------------
	-- window for batch creation date
	---------------------------------------------------
	--
	DECLARE @threshold DATETIME = DATEADD(DAY, -365, GETDATE())

	---------------------------------------------------
	-- earlier than batch creation window 
	-- (default for datasets with null start time)
	---------------------------------------------------
	--
	DECLARE @now datetime = GETDATE()
	--
	DECLARE @past DATETIME = '1/1/2000'
	--
	DECLARE @future DATETIME = DATEADD(MONTH, 3, @now)

	DECLARE @eventTypeID INT

	---------------------------------------------------
	-- Temp table for events to be added
	---------------------------------------------------
	--
	CREATE TABLE #Tmp_NewEvents (
		Target_ID INT,
		Event_Type int
	)

	---------------------------------------------------
	-- Look for Datasets that were not released, are corrupt/bad, or are marked for "Rerun"
	---------------------------------------------------
	--
	SET @eventTypeID = 20 -- 'Dataset Not Released'

	INSERT INTO #Tmp_NewEvents
		( Target_ID,
		  Event_Type 
		)
	SELECT
	  T_Dataset.Dataset_ID,
	  @eventTypeID
	FROM
	  T_Dataset
	WHERE
	  ( T_Dataset.DS_rating BETWEEN -9 AND 1 )
	AND 
	  T_Dataset.DS_created BETWEEN @window AND @now
		AND NOT EXISTS ( SELECT *
					     FROM dbo.T_Notification_Event AS TNE
					     WHERE TNE.Target_ID = T_Dataset.Dataset_ID
						   AND TNE.Event_Type = @eventTypeID )
	  

	---------------------------------------------------
	-- Look for Datasets that are released
	---------------------------------------------------
	--
	SET @eventTypeID = 21 -- 'Dataset Released'

	INSERT INTO #Tmp_NewEvents
		( Target_ID,
		  Event_Type 
		)
	SELECT
	  T_Dataset.Dataset_ID,
	  @eventTypeID
	FROM
	  T_Dataset
	WHERE
	  ( T_Dataset.DS_rating >= 2 )
	AND 
	  T_Dataset.DS_created BETWEEN @window AND @now
		AND NOT EXISTS ( SELECT *
					     FROM dbo.T_Notification_Event AS TNE
					     WHERE TNE.Target_ID = T_Dataset.Dataset_ID
						   AND TNE.Event_Type = @eventTypeID )


/*
 SELECT * FROM #Tmp_NewEvents
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
	  #Tmp_NewEvents.Event_Type,
	  #Tmp_NewEvents.Target_ID
	FROM
	  #Tmp_NewEvents
	WHERE
	  NOT EXISTS ( SELECT *
				   FROM T_Notification_Event TNE
				   WHERE TNE.Target_ID = #Tmp_NewEvents.Target_ID
					 AND TNE.Event_Type = #Tmp_NewEvents.Event_Type )
					
	---------------------------------------------------
	-- clean out batch events older than window
	---------------------------------------------------
	--
	DELETE FROM T_Notification_Event
	WHERE Event_Type IN (20, 21) AND
	      Entered < @window

	

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationDatasetEvents] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationDatasetEvents] TO [Limited_Table_Write] AS [dbo]
GO
