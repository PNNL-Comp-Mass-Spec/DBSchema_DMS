/****** Object:  StoredProcedure [dbo].[RequestArchiveUpdateTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.RequestArchiveUpdateTask
/****************************************************
**
**	Desc: Looks for dataset that needs to be archived
**        If found, job is assigned
**        to caller and job information is returned
**        in the output arguments
**
**
**	Auth: grk
**	Date:	12/03/2002
**			12/06/2002 dac - Corrected ArchivePath and ArchiveServerName outputs, changed Update State to 3 on success
**			09/27/2007 grk - Modified to have "standard" interface (http://prismtrac.pnl.gov/trac/ticket/537)
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
		Instrument_Name  varchar(24)
	) 

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset archive update requests for given storage server
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	-- consider datasets for archive update that are associated with an instrument
	-- whose currently assigned storage is on the requesting processor
	--
	INSERT INTO #XPD
	SELECT TOP 2
		T_Dataset.Dataset_ID,
		T_Instrument_Name.IN_class           AS Instrument_Class,
		T_Instrument_Name.IN_name            AS Instrument_Name
	FROM     
		T_Dataset INNER JOIN 
		t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN 
		T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN 
		T_Dataset_Archive ON T_Dataset.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID 
	WHERE    
		(t_storage_path.SP_machine_name = @StorageServerName) AND
		((T_Instrument_Name.IN_class = @InstrumentClass) OR (@InstrumentClass = 'none')) AND
		(T_Dataset_Archive.AS_update_state_ID = 2) AND
		(T_Dataset_Archive.AS_state_ID = 3 OR T_Dataset_Archive.AS_state_ID = 4)
		-- The following excludes datasets that currently have a job in progress
		AND (NOT EXISTS (SELECT * FROM T_Analysis_Job WHERE (AJ_StateID IN (2,3,9,10,11,12)) AND (AJ_datasetID = T_Dataset.Dataset_ID)))
	ORDER BY Dataset_ID
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
	SELECT TOP 1 @DatasetID = Dataset_ID
	FROM T_Dataset_Archive WITH ( HoldLock )
	     INNER JOIN #XPD
	       ON #XPD.Dataset_ID = T_Dataset_Archive.AS_Dataset_ID
	WHERE (T_Dataset_Archive.AS_update_state_ID = 2)
	ORDER BY #XPD.Dataset_ID
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
	-- set state
	---------------------------------------------------
	--
	If @infoOnly = 0
	begin
		-- Future: store the processor name (@processorName) in AS_update_processor
		--
		UPDATE T_Dataset_Archive
		SET AS_update_state_ID = 3,
			AS_update_processor = @StorageServerName
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
GRANT EXECUTE ON [dbo].[RequestArchiveUpdateTask] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestArchiveUpdateTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveUpdateTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestArchiveUpdateTask] TO [PNL\D3M580] AS [dbo]
GO
