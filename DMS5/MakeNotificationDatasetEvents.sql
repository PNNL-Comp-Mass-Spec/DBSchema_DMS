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
**  Auth: grk
**  Date: 04/02/2010 grk - Initial Release
**        04/02/2010 mem - Updated the "Not Released" check to cover Dataset Rating -9 to 1
**                       - Now also looking for "Released" datasets
**    
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

	DECLARE @eventTypetID INT

	---------------------------------------------------
	-- Temp table for events to be added
	---------------------------------------------------
	--
	CREATE TABLE #ENV (
		Target_ID INT,
		Event_Type int
	)

	---------------------------------------------------
	-- Look for Datasets that were not released, are corrupt/bad, or are marked for "Rerun"
	---------------------------------------------------
	--
	SET @eventTypetID = 20 -- 'Dataset Not Released'

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
	  ( T_Dataset.DS_rating BETWEEN -9 AND 1 )
	AND 
	  T_Dataset.DS_created BETWEEN @window AND @now
		AND NOT EXISTS ( SELECT
						*
					   FROM
						dbo.T_Notification_Event AS TNE
					   WHERE
						TNE.Target_ID = T_Dataset.Dataset_ID
						AND TNE.Event_Type = @eventTypetID )
	  

	---------------------------------------------------
	-- Look for Datasets that released
	---------------------------------------------------
	--
	SET @eventTypetID = 21 -- 'Dataset Released'

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
	  ( T_Dataset.DS_rating >= 2 )
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
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationDatasetEvents] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationDatasetEvents] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationDatasetEvents] TO [PNL\D3M580] AS [dbo]
GO
