/****** Object:  StoredProcedure [dbo].[MakeNotificationSamplePrepRequestEvents] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.MakeNotificationSamplePrepRequestEvents
/****************************************************
**
**  Desc: 
**  Adds sample prep request notification events 
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
	-- window for sample prep request activity
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
		ID,
		State + 10
	FROM
		T_Sample_Prep_Request
	WHERE
		( StateChanged > @window )
		AND NOT EXISTS ( SELECT
						*
					   FROM
						dbo.T_Notification_Event AS TNE
					   WHERE
						TNE.Target_ID = T_Sample_Prep_Request.ID
						AND TNE.Event_Type = ( T_Sample_Prep_Request.State + 10 ) )

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
		Event_Type BETWEEN 11 AND 19
		AND Entered < @window
	

GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationSamplePrepRequestEvents] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[MakeNotificationSamplePrepRequestEvents] TO [PNL\D3M578] AS [dbo]
GO
