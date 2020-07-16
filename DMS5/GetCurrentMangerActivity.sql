/****** Object:  StoredProcedure [dbo].[GetCurrentMangerActivity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetCurrentMangerActivity
/****************************************************
**
**	Desc: 
**	Get snapshot of current activity of managers
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 10/6/2003
**			  06/01/04 grk - fixed initial population of XT with jobs
**			  06/23/04 grk - Used AJ_start instead of AJ_finish in default population
**			  11/04/04 grk - Widened "Who" column of XT to match data in some item queries
**			  02/24/04 grk - fixed problem with null value for AJ_assignedProcessorName
**			  02/09/07 grk - added column to note that activity is stale (Ticket #377)
**			  02/27/07 grk - fixed prep manager reporting (Ticket #398)
**			  04/04/08 dac - changed output sort order to DESC
**			  09/30/09 grk - eliminated references to health log
**			  01/30/17 mem - Switch from DateDiff to DateAdd
**    
*****************************************************/
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	-- Get most recent manager activity 
	-- from health log and tracking entity states
	--
	-- 10/1/2003 grk

	-- temporary table to hold accumulated results
	--
	CREATE TABLE #XT (
		[Source] varchar(12),
		[When] datetime, 
		Who varchar(64), 
		What  varchar(256)
	)

	-- populate temporary table with known analysis managers
	--
	insert into #XT([When], Who, What, Source)
	SELECT  M.[When], cast('Analysis: ' + M.AJ_assignedProcessorName as varchar(32)) AS Who, 'Nothing in health log or in process, but active in last 3 mo.' AS What, 'Historic' as Source
	FROM
	(
		-- get distinct list of analysis managers 
		-- that have been active in the previous three months
		--
		SELECT ISNULL(AJ_assignedProcessorName, '(unknown)') as AJ_assignedProcessorName, 
		       ISNULL(MAX(AJ_start), CONVERT(DATETIME, '2003-01-01 00:00:00', 102)) as [When]
		FROM         T_Analysis_Job
		GROUP BY AJ_assignedProcessorName
		HAVING Max(AJ_finish) > DateAdd(month, -3, GETDATE())
	) M

/*
	-- get most recent entry from health log 
	-- broken down by which manager posted it
	--

	insert into #XT([When], Who, What, Source) 
	SELECT    posting_time as [When], posted_by as Who, message as What, 'Health' as Source
	FROM         T_Health_Entries
	WHERE     (Entry_ID IN
							(SELECT     MAX(Entry_ID)
								FROM          T_Health_Entries
							GROUP BY posted_by))
	AND posted_by not in 
	(
	SELECT Who from #XT
	)

	Update M
	Set M.[When] = T.[When], M.Who = T.Who, M.What = T.What, [Source] = 'Jobs'
	From #XT M inner Join 
	(
		-- get most recent entry from health log 
		-- broken down by which manager posted it
		SELECT     posting_time as [When], posted_by as Who, message as What, 'Health' as Source
		FROM         T_Health_Entries
		WHERE     (Entry_ID IN
								(SELECT     MAX(Entry_ID)
									FROM          T_Health_Entries
								GROUP BY posted_by))
	) T on M.Who = T.Who
	WHERE M.[When] < T.[When]
*/
	-- update any entries that have active job with later date than existing entry in XT
	--
	Update M
	Set M.[When] = T.[When], M.Who = T.Who, M.What = T.What, [Source] = 'Jobs'
	From #XT M inner Join 
	(
		-- get list of jobs in progress
		--
		SELECT     AJ_start as [When], 'Analysis: ' + AJ_assignedProcessorName as Who, 'Job in progress: ' + CAST(AJ_jobID AS varchar(12)) AS What
		FROM         T_Analysis_Job
		WHERE     (AJ_StateID = 2)
	) T on M.Who = T.Who
	WHERE M.[When] <= T.[When]


	-- update any entries that have active capture with later date (from event log) than health log
	--
	Update M
	Set M.[When] = T.[When], M.Who = T.Who, M.What = T.What, [Source] = 'Capture'
	From #XT M inner Join 
	(
		-- get list of captures in progress
		--
		SELECT     T_Event_Log.Entered AS [When], 
		'Capture: ' + t_storage_path.SP_machine_name AS Who, 
		'In Progress: ' + T_Dataset.Dataset_Num  AS What
		FROM         T_Dataset INNER JOIN
				t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
				T_Event_Log ON T_Dataset.Dataset_ID = T_Event_Log.Target_ID
		WHERE     (T_Dataset.DS_state_ID = 2) AND (T_Event_Log.Target_Type = 4)
	) T on M.Who = T.Who
	WHERE M.[When] < T.[When]


	-- update any entries that have active preparation with later date (from event log) than health log
	--
	Update M
	Set M.[When] = T.[When], M.Who = T.Who, M.What = T.What, [Source] = 'Preparation'
	From #XT M inner Join 
	(
		-- get list of preparation in progress
		--
		SELECT
			T_Event_Log.Entered AS [When], 
			'In Progress: ' + T_Dataset.Dataset_Num AS What, 
			'Preparation: ' + T_Dataset.DS_PrepServerName AS Who
		FROM
			T_Dataset INNER JOIN
			t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
			T_Event_Log ON T_Dataset.Dataset_ID = T_Event_Log.Target_ID
		WHERE     
			(T_Dataset.DS_state_ID = 7) AND 
			(T_Event_Log.Target_Type = 4) AND 
			(T_Event_Log.Target_State = 7)
	) T on M.Who = T.Who
	WHERE M.[When] < T.[When]

	-- update any entries that have active archive with later date (from event log) than health log
	--
	Update M
	Set M.[When] = T.[When], M.Who = T.Who, M.What = T.What, [Source] = 'Archive'
	From #XT M inner Join 
	(
		-- get list of archive in progress
		--
	SELECT     T_Event_Log.Entered AS [When], 'Archive: ' + t_storage_path.SP_machine_name AS Who, 'In Progress: ' + T_Dataset.Dataset_Num AS What
	FROM         T_Dataset INNER JOIN
						t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
						T_Event_Log ON T_Dataset.Dataset_ID = T_Event_Log.Target_ID INNER JOIN
						T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	WHERE     (T_Event_Log.Target_Type = 6) AND (T_Dataset_Archive.AS_state_ID IN (2, 7))
	) T on M.Who = T.Who
	WHERE M.[When] < T.[When]

/**/

	/*
	-- FUTURE: get list of archive update in progress
	--
	*/
Done:
	-- dump contents of temporary table
	--
	select
		Source, 
		[When], 
		Who, 
		What,
		CASE WHEN DATEDIFF(hour, [When], getdate()) > 6 THEN 'ALERT' ELSE '' END as #Alert
	from #XT 
	ORDER by Who DESC

return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetCurrentMangerActivity] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCurrentMangerActivity] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCurrentMangerActivity] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCurrentMangerActivity] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCurrentMangerActivity] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetCurrentMangerActivity] TO [Limited_Table_Write] AS [dbo]
GO
