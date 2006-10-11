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
**	Date:	03/10/2003
**			06/02/2005 grk - Modified for prep servers
**			07/11/2006 mem - Added check for too many datasets (per instrument) being simultaneously captured/prepped
**			07/17/2006 mem - Limiting each prep server to queue up just one dataset, utilizing a rolling exclusion window of 11 minutes
**			07/19/2006 mem - Updated to obtain capture throttling parameters from T_Instrument_Name
**			10/10/2006 mem - Updated to use a timeout value of 2 hours when looking for datasets with state 2="Capture in Progress"
**    
*****************************************************/
(
	@StorageServerName varchar(64),
	@PrepServerName varchar(64),
	@dataset varchar(128) output,
	@DatasetID int output,
	@Method varchar(24) output,
	@InstrumentClass varchar(64) output, 
	@SourceVol varchar(256) output, 
	@SourcePath varchar(256) output, 
	@StorageVol varchar(256) output, 
	@storagePath varchar(256) output, 
	@StorageVolExternal varchar(256) output, -- use instead of @StorageVol when manager is not on same machine as dataset folder
	@rating smallint output,
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	set @DatasetID = 0
	set @dataset = ''
	set @Method = ''
	set @InstrumentClass = ''
	set @SourceVol = '' 
	set @SourcePath  = ''
	set @StorageVol  = ''
	set @storagePath = ''
	set @StorageVolExternal = ''
	
	declare @storageID int
	declare @SkippedInstrumentRowCount int
	set @SkippedInstrumentRowCount = 0
	
	---------------------------------------------------
	-- The following defines the timeout length for excluding datasets 
	-- with state 2="Capture in Progress" when populating #TmpInstrumentsToSkip
	---------------------------------------------------
	declare @CaptureTimeoutLengthHours int
	set @CaptureTimeoutLengthHours = 2
	
	---------------------------------------------------
	-- Perform a preliminary scan of V_GetDatasetsForCaptureTask
	-- to see if any datasets are available for @StorageServerName
	---------------------------------------------------
	--		
	SELECT TOP 1 @storageID = StorageID
	FROM V_GetDatasetsForCaptureTask
	WHERE (StorageServerName = @StorageServerName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myRowCount = 0
	begin
		set @message = 'No candidate datasets available'
		goto done
	end

	---------------------------------------------------
	-- temporary table to hold candidate capture requests
	---------------------------------------------------

	CREATE TABLE #XPD (
			Dataset varchar(128), 
			Method varchar(24), 
			InstrumentClass varchar(64), 
			SourceVolume varchar(256), 
			sourcePath varchar(256), 
			StorageVolServer varchar(256), 
			storagePath varchar(256), 
			StorageVolClient varchar(256), 
			StorageID int, 
			Dataset_ID int,
			DS_rating smallint
	) 

	CREATE TABLE #TmpInstrumentsToSkip (
		Instrument_ID int,
		Log_Level tinyint,					-- 0=None, 1=Normal, 2=Debug
		Skip_Message varchar(128)
	)
	
	---------------------------------------------------
	-- Construct list of instruments that have datasets 
	--  in state 1=New, but already have IN_Max_Simultaneous_Captures
	--  or more captures in progress
	-- Exclude any datasets that started capture over 
	--  @CaptureTimeoutLengthHours before the current time
	--  (since the capture most likely failed)
	---------------------------------------------------
	--
	INSERT INTO #TmpInstrumentsToSkip (Instrument_ID, Log_Level, Skip_Message)
	SELECT	InstName.Instrument_ID, 
			InstName.IN_Capture_Log_Level,
			InstName.IN_Name + ' has reached the maximum number of simultaneous dataset captures (' + 
			 Convert(varchar(9), InstName.IN_Max_Simultaneous_Captures) + '); called by ' + @PrepServerName
	FROM T_Dataset DS INNER JOIN
		 V_Assigned_Storage VAS ON 
		 DS.DS_instrument_name_ID = VAS.Instrument_ID INNER JOIN
		 T_Instrument_Name InstName ON 
		 DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN (
			SELECT VAS.Instrument_ID
			FROM T_Dataset DS INNER JOIN
				 V_Assigned_Storage VAS ON
				 DS.DS_instrument_name_ID = VAS.Instrument_ID
			WHERE DS.DS_state_ID = 1 AND
				  VAS.SP_machine_name = @StorageServerName
			GROUP BY Instrument_ID
		 ) NewDatasetsQ ON VAS.Instrument_ID = NewDatasetsQ.Instrument_ID INNER JOIN 
		 T_Event_Log EL ON EL.Target_ID = DS.Dataset_ID AND 
						   EL.Target_Type = 4 AND
						   EL.Target_State = DS.DS_State_ID
	WHERE DS.DS_state_ID = 2 AND 
		  EL.Entered >= DATEADD(hour, -@CaptureTimeoutLengthHours, GETDATE())
	GROUP BY InstName.Instrument_ID, InstName.IN_name, InstName.IN_Max_Simultaneous_Captures, InstName.IN_Capture_Log_Level
	HAVING (COUNT(DISTINCT DS.Dataset_ID) >= InstName.IN_Max_Simultaneous_Captures )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	set @SkippedInstrumentRowCount = @myRowCount 
	if @myError <> 0
	begin
		set @message = 'Error checking for instruments with too many dataset captures in progress'
		goto done
	end

	---------------------------------------------------
	-- Append to #TmpInstrumentsToSkip the list of instruments 
	--  that have datasets in state 1=New, but have IN_Max_Queued_Datasets or more
	--  datasets in state 2 or 6 that are mapped to @PrepServerName
	--  and that entered that state within the last IN_Capture_Exclusion_Window minutes
	---------------------------------------------------
	--
	INSERT INTO #TmpInstrumentsToSkip (Instrument_ID, Log_Level, Skip_Message)
	SELECT	InstName.Instrument_ID, 
			InstName.IN_Capture_Log_Level,
			@PrepServerName + ' has reached the maximum number of queued datasets (' +
			Convert(varchar(9), InstName.IN_Max_Queued_Datasets) + ') for ' + InstName.IN_Name
	FROM T_Dataset DS INNER JOIN
		 V_Assigned_Storage VAS ON 
		 DS.DS_instrument_name_ID = VAS.Instrument_ID INNER JOIN
		 T_Instrument_Name InstName ON 
		 DS.DS_instrument_name_ID = InstName.Instrument_ID INNER JOIN (
			SELECT VAS.Instrument_ID
			FROM T_Dataset DS INNER JOIN
				 V_Assigned_Storage VAS ON
				 DS.DS_instrument_name_ID = VAS.Instrument_ID
			WHERE DS.DS_state_ID = 1 AND
				  VAS.SP_machine_name = @StorageServerName
			GROUP BY Instrument_ID
		 ) NewDatasetsQ ON VAS.Instrument_ID = NewDatasetsQ.Instrument_ID INNER JOIN 
		 T_Event_Log EL ON EL.Target_ID = DS.Dataset_ID AND 
						   EL.Target_Type = 4 AND
						   EL.Target_State = DS.DS_State_ID
	WHERE DS.DS_state_ID IN (2, 6) AND
		  DS.DS_PrepServerName = @PrepServerName AND 
		  EL.Entered >= DATEADD(second, -InstName.IN_Capture_Exclusion_Window*60.0, GETDATE())
	GROUP BY InstName.Instrument_ID, InstName.IN_name, InstName.IN_Max_Queued_Datasets, InstName.IN_Capture_Log_Level
	HAVING (COUNT(DISTINCT DS.Dataset_ID) >= InstName.IN_Max_Queued_Datasets)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	set @SkippedInstrumentRowCount = @SkippedInstrumentRowCount + @myRowCount 
	if @myError <> 0
	begin
		set @message = 'Error checking for instruments with too many datasets associated with prep server'
		goto done
	end

	if @SkippedInstrumentRowCount > 0
	begin
		---------------------------------------------------
		-- Post a status message to T_Log_Entries for the instruments 
		--  present in #TmpInstrumentsToSkip with Log_Level >= 2
		-- Using Group By and Min() to limit to just one entry per instrument
		---------------------------------------------------

		INSERT INTO T_Log_Entries (posted_by, posting_time, type, message)
		SELECT 'RequestCaptureTask', GetDate(), 'Normal', MIN(Skip_Message)
		FROM #TmpInstrumentsToSkip
		WHERE Log_Level >= 2
		GROUP BY Instrument_ID
		ORDER BY Instrument_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error logging skipped instruments'
			goto done
		end
	end
		

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset capture requests for given storage server
	-- and prep server (if specified)
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	-- Consider datasets for capture that are associated with an instrument
	--  whose currently assigned storage is on the requesting processor
	
	INSERT INTO #XPD
	SELECT TOP 5
		Dataset, 
		Method, 
		InstrumentClass, 
		SourceVolume, 
		sourcePath, 
		StorageVolServer, 
		storagePath, 
		StorageVolClient, 
		StorageID, 
		Dataset_ID,
		DS_rating
	FROM V_GetDatasetsForCaptureTask LEFT OUTER JOIN 
		 #TmpInstrumentsToSkip ON V_GetDatasetsForCaptureTask.Instrument_ID = #TmpInstrumentsToSkip.Instrument_ID
	WHERE (StorageServerName = @StorageServerName) AND
		  ((InstrumentClass = @InstrumentClass) OR (@InstrumentClass = '')) AND
		  (#TmpInstrumentsToSkip.Instrument_ID IS NULL)
	ORDER BY Dataset_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end
	--
	if @myRowCount = 0
	begin
		set @message = 'No candidate datasets available'
		goto done
	end
	
	-- Start transaction
	--
	declare @transName varchar(32)
	set @transName = 'RequestCaptureTask'
	begin transaction @transName
	
	---------------------------------------------------
	-- Select and lock a specific dataset by joining
	-- from the local pool to the actual analysis job table
	-- Note:  This takes a lock on the selected row
	-- so that that dataset can be exclusively assigned,
	-- but only locks T_Dataset table, not the others
	-- involved in resolving the request
	---------------------------------------------------
/**/
	SELECT top 1
		@Dataset = #XPD.Dataset, 
		@Method = #XPD.Method, 
		@InstrumentClass = #XPD.InstrumentClass, 
		@SourceVol = #XPD.SourceVolume, 
		@SourcePath = #XPD.SourcePath, 
		@StorageVol = #XPD.StorageVolServer, 
		@StorageVolExternal = #XPD.StorageVolClient,
		@storagePath = #XPD.storagePath,
		@storageID = #XPD.StorageID,
		@DatasetID = #XPD.Dataset_ID,
		@rating = #XPD.DS_rating
	FROM
		T_Dataset with (HoldLock) 
		inner join #XPD on #XPD.Dataset_ID = T_Dataset.Dataset_ID 
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
		rollback transaction @transName
		goto done
	end
	
	---------------------------------------------------
	-- set state and storage path and prep server
	---------------------------------------------------
	--
	UPDATE    T_Dataset
	SET 
		DS_state_ID = 2, 
		DS_storage_path_ID = @storageID,
		DS_PrepServerName = @PrepServerName
	WHERE     (Dataset_ID = @DatasetID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Update operation failed'
		goto done
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
