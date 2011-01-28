/****** Object:  StoredProcedure [dbo].[RequestArchiveTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.RequestArchiveTask
/****************************************************
**
**	Desc: Looks for dataset that needs to be archived
**        If found, job is assigned
**        to caller and job information is returned
**        in the output arguments
**
**
**	Auth:	grk
**	Date:	12/2/2002
**			05/10/2005 grk - changed select logic to do oldest datasets first
**			02/20/2006 grk - for QC preference
**			09/27/2007 grk - Modified to have "standard" interface (http://prismtrac.pnl.gov/trac/ticket/537)
**			10/09/2007 grk - Factored out archive path assignment code into GetAssignedArchivePath (ticket 537)
**			11/01/2007 grk - Added 53000 return code when no tasks are available
**			05/31/2009 mem - Decreased population of #XPD to be limited to 5 rows
**						   - Now recording storage server name in field AS_update_processor
**			06/02/2009 mem - Decreased population of #XPD to be limited to 2 rows
**    
*****************************************************/
(
	@StorageServerName varchar(64),
	@DatasetID int output,
	@InstrumentClass varchar(32) output, -- supply input value to request a particular instrument class
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

	---------------------------------------------------
	-- The verification manager expects a non-zero return value if no jobs are available
	-- Code 53000 is used for this
	---------------------------------------------------
	--
	declare @taskNotAvailableErrorCode int
	set @taskNotAvailableErrorCode = 53000

	---------------------------------------------------
	-- temporary table to hold candidate capture requests
	---------------------------------------------------

	CREATE TABLE #XPD (
		Dataset_ID  int,
		Instrument_Class varchar(32), 
		Instrument_Name  varchar(24),
		Preference tinyint,
		Priority int
	) 

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset archive requests for given storage server
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	-- consider datasets for archive that are associated with an instrument
	-- whose currently assigned storage is on the requesting processor
	--
	INSERT INTO #XPD
	SELECT TOP 2
		T_Dataset.Dataset_ID,
		T_Instrument_Name.IN_class           AS Instrument_Class,
		T_Instrument_Name.IN_name            AS Instrument_Name,
		dbo.DatasetPreference(T_Dataset.Dataset_Num) AS Preference,
		99 as Priority
	FROM
		T_Dataset INNER JOIN
		t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN
        T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID LEFT OUTER JOIN
        T_Analysis_Job ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
	WHERE 
		(t_storage_path.SP_machine_name = @StorageServerName) AND 
		((T_Instrument_Name.IN_class = @InstrumentClass) OR (@InstrumentClass = 'none')) AND
		(T_Dataset_Archive.AS_state_ID = 1) AND
		(NOT (ISNULL(T_Analysis_Job.AJ_StateID, 0) IN (2, 3, 9, 10, 11, 12)))
	ORDER BY Dataset_ID ASC
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'could not load temporary table'
		goto done
	end

   	---------------------------------------------------
	-- If there are no candidates, bail
	---------------------------------------------------
	if @myRowCount = 0
	begin
		set @myError = @taskNotAvailableErrorCode
		goto Done
	end

   	---------------------------------------------------
	-- datasets with pending jobs get priority
	-- of their highest priority job
	---------------------------------------------------

	UPDATE M
	SET M.Priority = CASE
	                     WHEN M.Priority > ISNULL(T_Analysis_Job.AJ_priority, 99) 
	                     THEN ISNULL(T_Analysis_Job.AJ_priority, 99)
	                     ELSE M.Priority
	                 END
	FROM #XPD M
	     INNER JOIN T_Analysis_Job
	       ON T_Analysis_Job.AJ_DatasetID = M.Dataset_ID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'error updating job priority'
		goto done
	end

   	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'RequestArchiveTask'
	begin transaction @transName
	
   	---------------------------------------------------
	-- find a task matching the input request
	---------------------------------------------------
	--
	declare @InstrumentName varchar(24)
	--
	SELECT TOP 1 
		@DatasetID = Dataset_ID, 
		@InstrumentClass = Instrument_Class, 
		@InstrumentName = Instrument_Name
	FROM
		T_Dataset_Archive with (HoldLock) inner join  
		#XPD on #XPD.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID 
	WHERE (T_Dataset_Archive.AS_state_ID = 1)
	ORDER BY #XPD.Preference DESC, #XPD.Priority, #XPD.Dataset_ID
	--
	SELECT @myError = @@error
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error trying to find archive record'
		goto done
	end
	
	---------------------------------------------------
	-- bail if no task found
	---------------------------------------------------

	if @datasetID = 0
	begin
		rollback transaction @transName
		set @message = 'Could not find archive record'
		goto done
	end
	
   	---------------------------------------------------
	-- get assigned archive path
	---------------------------------------------------
	--
	declare @archivePathID int
	set @archivePathID = 0
	--
	exec @myError = GetAssignedArchivePath
						@datasetID,
						@archivePathID output,
						@message output
/*
	--
	SELECT     
		@archivePathID = Archive_Path_ID
	FROM         V_Assigned_Archive_Storage
	WHERE     (Instrument_Name = @InstrumentName)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @archivePathID = 0
*/
	if @myError <> 0
	begin
		rollback transaction @transName
		goto done
	end
		
   	---------------------------------------------------
	-- set state and archive path
	---------------------------------------------------
	--
	If @infoOnly = 0
	begin
		-- Future: store the processor name (@processorName) in AS_archive_processor
		--
		UPDATE T_Dataset_Archive
		SET AS_state_ID = 2,
		    AS_storage_path_ID = @archivePathID,
		    AS_archive_processor = @StorageServerName
		WHERE (AS_Dataset_ID = @datasetID)
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
GRANT EXECUTE ON [dbo].[RequestArchiveTask] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveTask] TO [PNL\D3M580] AS [dbo]
GO
