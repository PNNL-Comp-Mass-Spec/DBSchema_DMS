/****** Object:  StoredProcedure [dbo].[RequestCaptureTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.RequestCaptureTask
/****************************************************
**
**	Desc: 
**	Looks for dataset that needs to captured
**	If found, dataset is set 'In Progress'
**	and information needed for capture task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**  if DatasetID is returned 0, no available dataset was found
**
**	Auth:	grk
**	03/10/2003 -- initial release
**	06/02/2005 grk - Modified for prep servers
**	07/11/2006 mem - Added check for too many datasets (per instrument) being simultaneously captured/prepped
**	07/17/2006 mem - Limiting each prep server to queue up just one dataset, utilizing a rolling exclusion window of 11 minutes
**	07/19/2006 mem - Updated to obtain capture throttling parameters from T_Instrument_Name
**	10/10/2006 mem - Updated to use a timeout value of 2 hours when looking for datasets with state 2="Capture in Progress"
**	05/16/2007 mem - Updated to use DS_Last_Affected to look for simultaneous captures or multiple queued prep tasks (Ticket:478)
**	09/25/2007 grl - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**    
*****************************************************/
(
	@StorageServerList varchar(256),
	@machineName varchar(64), -- prep server name
	@mgrName varchar(64), 
	@DatasetID int output,
	@message varchar(512) output,
	@infoOnly tinyint = 0            -- Set to 1 to preview the task that would be returned
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	set @DatasetID = 0
	set @infoOnly = IsNull(@infoOnly, 0)

	declare @storageID int
	
	---------------------------------------------------
	-- The capture manager expects a non-zero return value if no jobs are available
	-- Code 53000 is used for this
	---------------------------------------------------
	--
	declare @taskNotAvailableErrorCode int
	set @taskNotAvailableErrorCode = 53000
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	set @machineName = IsNull(@machineName, '')

	if Len(LTrim(RTrim(@machineName))) = 0
	begin
		set @message = 'Machine name is blank'
		set @myError = 50000
		goto Done
	end

	---------------------------------------------------
	-- Convert delimited list of storage servers to table variable
	---------------------------------------------------
	
	DECLARE @StorageServerTable TABLE(Item varchar(128))
	--
	INSERT INTO @StorageServerTable(Item)
	SELECT Item FROM dbo.MakeTableFromList(@StorageServerList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error converting list of storage server list'
		goto Done
	end
	
	---------------------------------------------------
	-- temporary table to hold candidate capture requests
	---------------------------------------------------

	CREATE TABLE #PD (
		DatasetID  int,
		State  int,
		InstrumentName varchar(64),
		MachineName varchar(64) NULL,
		Max_Simultaneous_Captures smallint ,
		Max_Queued_Datasets smallint,
		Capture_Exclusion_Window real,
		is_purgable tinyint,
		Storage_Path_ID int
	) 

	---------------------------------------------------
	-- Populate temporary table with candidate tasks
	-- for datasets that use any storage server in the list
	---------------------------------------------------

	INSERT INTO #PD (
		DatasetID, 
		State, 
		InstrumentName, 
		MachineName,
		Max_Simultaneous_Captures,
		Max_Queued_Datasets,
		Capture_Exclusion_Window,
		is_purgable,
		Storage_Path_ID
	)
	SELECT 
	  T_Dataset.Dataset_ID AS DatasetID,
	  T_Dataset.DS_state_ID AS State,
	  T_Instrument_Name.IN_name AS InstrumentName,
	  T_Dataset.DS_PrepServerName AS MachineName,
	  T_Instrument_Name.IN_Max_Simultaneous_Captures AS Max_Simultaneous_Captures,
	  T_Instrument_Name.IN_Max_Queued_Datasets AS Max_Queued_Datasets,
	  T_Instrument_Name.IN_Capture_Exclusion_Window AS Capture_Exclusion_Window,
	  T_Instrument_Class.is_purgable AS is_purgable,
	  t_storage_path.SP_path_ID AS Storage_Path_ID
	FROM   
	  T_Dataset
	  INNER JOIN T_Instrument_Name
		ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
	  INNER JOIN t_storage_path
		ON T_Instrument_Name.IN_storage_path_ID = t_storage_path.SP_path_ID
	  INNER JOIN T_Instrument_Class
		ON T_Instrument_Name.IN_class = T_Instrument_Class.IN_class
	WHERE
		(T_Dataset.DS_state_ID = 1) AND
		(SP_machine_name IN (SELECT Item FROM @StorageServerTable))
	ORDER BY 
		DatasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary candidate table'
		goto Done
	end

	---------------------------------------------------
	-- Exit if no candidates were found
	---------------------------------------------------
	--		
	if @myRowCount = 0
	begin
		set @myError = @taskNotAvailableErrorCode
		set @message = 'No candidate datasets available'
		goto done
	end

	---------------------------------------------------
	-- The following defines the time window length for 
	-- excluding datasets from quota checks
	---------------------------------------------------
	declare @CaptureTimeoutLengthHours int
	set @CaptureTimeoutLengthHours = 2
	
 	---------------------------------------------------
	-- remove candidates from temp table where instrument
	-- is already at the max allowed simultaneous captures
	---------------------------------------------------
	--
	DELETE FROM #PD
	WHERE InstrumentName IN 
	(
		-- instruments that have max allowed captures already
		--
		SELECT 
			IN_name
		FROM   
			T_Instrument_Name INNER JOIN 
			( 
			-- number of current captures in progress for each instrument
			-- that were initiated with within time window
			SELECT 
				DS_instrument_name_ID as Instrument_ID, 
				COUNT(*)  AS Captures_In_Progress
			FROM  
				T_Dataset INNER JOIN
                T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID 
			WHERE DS_state_ID = 2 AND 
			DS_Last_Affected >= DATEADD(hour, -@CaptureTimeoutLengthHours, GETDATE())
			GROUP BY DS_instrument_name_ID 
			) AS S
		ON S.Instrument_ID = T_Instrument_Name.Instrument_ID
		WHERE S.Captures_In_Progress >= IN_Max_Simultaneous_Captures
	)            
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error attempting to remove instruments that are at capture quota'
		goto Done
	end

	---------------------------------------------------
	-- If any candidates were removed by throttling
	-- check if any are left and exit if not
	---------------------------------------------------
	if @myRowCount > 0
		begin
		set @myRowCount = 0
		SELECT @myRowCount = count(*) FROM #PD
		if @myRowCount = 0
		begin
			set @myError = @taskNotAvailableErrorCode
			set @message = 'No candidate datasets available after instrument capture throttling'
			goto done
		end
	end
	
	---------------------------------------------------
	-- Remove candidates that would cause prep server 
	-- to accept more capture tasks from a given instrument 
	-- than the quota established for that instrument
	--
	-- Instruments that have datasets in state 1=New, 
	-- but have IN_Max_Queued_Datasets or more
	-- datasets in state 2 or 6 that are mapped to @machineName
	-- and that entered that state within the last 
	-- IN_Capture_Exclusion_Window minutes
	---------------------------------------------------

	DELETE FROM #PD
	WHERE InstrumentName IN 
	(
	SELECT
		t_storage_path.SP_instrument_name
	FROM
		T_Dataset INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID AND 
		T_Dataset.DS_Last_Affected >= DATEADD(minute, - (T_Instrument_Name.IN_Capture_Exclusion_Window * 60.0), GETDATE()) INNER JOIN
		t_storage_path ON T_Instrument_Name.IN_storage_path_ID = t_storage_path.SP_path_ID
	WHERE
		(T_Dataset.DS_state_ID IN (2, 6)) AND (T_Dataset.DS_PrepServerName = @machineName)
	GROUP BY t_storage_path.SP_instrument_name, T_Instrument_Name.IN_Max_Queued_Datasets
	HAVING (COUNT(*) >= T_Instrument_Name.IN_Max_Queued_Datasets)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking for instruments with too many datasets associated with prep server'
		goto done
	end           
	--
	if @myError <> 0
	begin
		goto Done
	end

	---------------------------------------------------
	-- If any candidates were removed by throttling
	-- check if any are left and exit if not
	---------------------------------------------------
	if @myRowCount > 0
		begin
		set @myRowCount = 0
		SELECT @myRowCount = count(*) FROM #PD
		if @myRowCount = 0
		begin
			set @myError = @taskNotAvailableErrorCode
			set @message = 'No candidate datasets available after prep server capture throttling'
			goto done
		end
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'RequestCaptureTask'
	begin transaction @transName

	---------------------------------------------------
	-- Select and lock a specific dataset by joining
	-- from the local pool to the actual dataset table.
	-- Note:  This takes a lock on the selected row
	-- so that that dataset can be exclusively assigned,
	-- but only locks T_Dataset table, not the others
	-- involved in resolving the request
	---------------------------------------------------

	SELECT top 1
		@DatasetID = #PD.DatasetID,
		@storageID = Storage_Path_ID
	FROM
		T_Dataset with (HoldLock) 
		inner join #PD on #PD.DatasetID = T_Dataset.Dataset_ID 
	WHERE (T_Dataset.DS_state_ID = 1)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'error finding entry in main table'
		goto done
	end
	
	if @DatasetID = 0
	begin
		set @myError = @taskNotAvailableErrorCode
		rollback transaction @transName
		goto done
	end
	
	---------------------------------------------------
	-- set state and storage path and prep server
	---------------------------------------------------
	--
	If @infoOnly = 0
	begin
		UPDATE T_Dataset
		SET 
			DS_state_ID = 2, 
			DS_storage_path_ID = @storageID,
			DS_PrepServerName = @machineName
		WHERE
			Dataset_ID = @DatasetID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Update operation failed'
			goto done
		end
	end

	commit transaction @transName

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[RequestCaptureTask] TO [DMS_SP_User]
GO
