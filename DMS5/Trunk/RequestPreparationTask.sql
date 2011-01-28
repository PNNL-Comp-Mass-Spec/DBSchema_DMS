/****** Object:  StoredProcedure [dbo].[RequestPreparationTask] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure RequestPreparationTask
/****************************************************
**
**	Desc: 
**	Looks for dataset that needs to Prepared
**	If found, dataset is set 'Prep. In Progress' state
**	and information needed for preparation task is returned
**	in the output arguments
**
**	Return values: 0: success, otherwise, error code
**
**  if DatasetID is returned 0, no available dataset was found
**
**	Auth: grk
**	11/14/2002 -- initial release
**  07/16/2003 dac - Added @StorageVolExternal to list of output arguments being cleared prior to transaction start
**  05/10/2005 grk - changed select logic to do oldest datasets first
**  06/02/2005 grk - added handling for prep server
**  07/01/2005 grk - add sorting by dataset ID for candidate pool select
**  02/20/2006 grk - removed sorting by dataset ID for candidate pool select (for QC preference in view)
**  09/25/2007 grk - Rolled back to DMS from broker (http://prismtrac.pnl.gov/trac/ticket/537)
**    
*****************************************************/
	@StorageServerList varchar(256), -- list of storage server that manager supports
	@machineName varchar(64),        -- restricts candidates to match prep machine (optional)
	@InstrumentClass varchar(32),    -- restricts candidates according to intrument class (optional)
	@mgrName varchar(50),
	@DatasetID int = 0 output,       -- dataset ID assigned; 0 if no job available
	@message varchar(512)='' output,
	@infoOnly tinyint = 0            -- Set to 1 to preview the task that would be returned
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
	-- The prep manager expects a non-zero return value 
	-- if no prep candidates are available
	-- Code 53000 is used for this
  	---------------------------------------------------
	declare @taskNotAvailableErrorCode int
	set @taskNotAvailableErrorCode = 53000

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

	CREATE TABLE #XPD (
		Dataset_ID int
	) 

	---------------------------------------------------
	-- fix up instrument class argument
	---------------------------------------------------
	
	if @InstrumentClass = 'none'
		set @InstrumentClass = ''

	---------------------------------------------------
	-- populate temporary table with a small pool of 
	-- dataset capture requests for given storage server
	-- and prep server (if specified)
	-- Note:  This takes no locks on any tables
	---------------------------------------------------

	-- consider datasets for capture that are associated with an instrument
	-- whose currently assigned storage is on the requesting processor
	
	INSERT INTO #XPD
	SELECT 
	  T_Dataset.Dataset_ID
	FROM     
	  T_Dataset INNER JOIN 
	  T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID INNER JOIN 
	  t_storage_path ON T_Dataset.DS_storage_path_ID = t_storage_path.SP_path_ID 
	WHERE
		T_Dataset.DS_state_ID = 6 AND
		(SP_machine_name IN (SELECT Item FROM @StorageServerTable) ) AND 
		((IN_class = @InstrumentClass) OR (@InstrumentClass = '')) AND
		(DS_PrepServerName = @machineName)
	ORDER BY 
		dbo.Datasetpreference(T_Dataset.Dataset_Num) DESC,
		T_Dataset.Dataset_ID
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
		set @myError = @taskNotAvailableErrorCode
		goto done
	end

   	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'RequestCaptureTask'
	begin transaction @transName
	
   	---------------------------------------------------
	-- find a dataset matching the input request
	---------------------------------------------------
	--
	-- get dataset for Preparation that is in the 'Received' state 
	-- and that is associated with a storage path that is on the requesting processor
	--
	SELECT top 1
		@DatasetID = #XPD.Dataset_ID
	FROM
		T_Dataset with (HoldLock) INNER JOIN 
		#XPD on #XPD.Dataset_ID = T_Dataset.Dataset_ID 
	WHERE (T_Dataset.DS_state_ID = 6)
	ORDER BY T_Dataset.Dataset_ID ASC
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Find dataset operation failed'
		goto done
	end

   	---------------------------------------------------
	-- Check to see if dataset was found
	---------------------------------------------------
	
	if @DatasetID = 0
	begin
		rollback transaction @transName
		set @message = 'No datasets available'
		goto done
	end
	
   	---------------------------------------------------
	-- set state and storage path
	---------------------------------------------------
	--
	If @infoOnly = 0
	begin
		UPDATE T_Dataset
		SET 
			DS_state_ID = 7
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
GRANT ALTER ON [dbo].[RequestPreparationTask] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestPreparationTask] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTask] TO [D3L243] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[RequestPreparationTask] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTask] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTask] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RequestPreparationTask] TO [PNL\D3M580] AS [dbo]
GO
