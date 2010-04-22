/****** Object:  StoredProcedure [dbo].[UpdateArchiveDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateArchiveDatasets] 
/****************************************************
**
**	Desc:
**      Updates archive parameters to new values for datasets in list
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	08/21/2007
**			03/28/2008 mem - Added optional parameter @callingUser; if provided, then will call AlterEventLogEntryUserMultiID (Ticket #644)
**			08/04/2008 mem - Now updating column AS_instrument_data_purged (Ticket #683)
**			03/23/2009 mem - Now updating AS_Last_Successful_Archive when the archive state is 3=Complete (Ticket #726)
**    
*****************************************************/
(
    @datasetList varchar(6000),
    @archiveState varchar(32) = '',
    @updateState varchar(32) = '',
    @mode varchar(12) = 'update',
    @message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	declare @msg varchar(512)
	declare @list varchar(1024)

	declare @ArchiveStateUpdated tinyint
	declare @UpdateStateUpdated tinyint
	set @ArchiveStateUpdated = 0
	set @UpdateStateUpdated = 0

	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	if @datasetList = ''
	begin
		set @msg = 'Dataset list is empty'
		RAISERROR (@msg, 10, 1)
		return 51001
	end

	---------------------------------------------------
	--  Create temporary table to hold list of datasets
	---------------------------------------------------
 
 	CREATE TABLE #TDS (
		DatasetNum varchar(128)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Failed to create temporary dataset table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Populate table from dataset list  
	---------------------------------------------------

	INSERT INTO #TDS
	(DatasetNum)
	SELECT DISTINCT Item
	FROM MakeTableFromList(@datasetList)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error populating temporary dataset table'
		RAISERROR (@msg, 10, 1)
		return 51007
	end

 	---------------------------------------------------
	-- Verify that all datasets exist 
	---------------------------------------------------
	--
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN cast(DatasetNum as varchar(12))
		ELSE ', ' + cast(DatasetNum as varchar(12))
		END
	FROM
		#TDS
	WHERE 
		NOT DatasetNum IN (SELECT Dataset_Num FROM T_Dataset)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error checking dataset existence'
		return 51007
	end
	--
	if @list <> ''
	begin
		set @message = 'The following datasets from list were not in database:"' + @list + '"'
		return 51007
	end
	
	declare @datasetCount int
	set @datasetCount = 0
	
	SELECT @datasetCount = COUNT(*) 
	FROM #TDS
	
	set @message = 'Number of affected datasets:' + cast(@datasetCount as varchar(12))

	---------------------------------------------------
	-- Resolve archive state
	---------------------------------------------------
	declare @archiveStateID int
	set @archiveStateID = 0
	--
	if @archiveState <> '[no change]'
	begin
		--
		SELECT	@archiveStateID = DASN_StateID
		FROM	T_DatasetArchiveStateName
		WHERE	(DASN_StateName = @archiveState)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up state name'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		--
		if @archiveStateID = 0
		begin
			set @msg = 'Could not find state'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- if @archiveState
	
	
	---------------------------------------------------
	-- Resolve update state
	---------------------------------------------------
	declare @updateStateID int
	set @updateStateID = 0
	--
	if @updateState <> '[no change]'
	begin
		--
		SELECT @updateStateID =  AUS_stateID
		FROM T_Archive_Update_State_Name
		WHERE (AUS_name = @updateState)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking up update state name'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
		--
		if @updateStateID = 0
		begin
			set @msg = 'Could not find update state'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end -- if @updateState
	
	
 	---------------------------------------------------
	-- Update datasets from temporary table
	-- in cases where parameter has changed
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0

		---------------------------------------------------
		declare @transName varchar(32)
		set @transName = 'UpdateArchiveDatasets'
		begin transaction @transName

		-----------------------------------------------
		if @archiveState <> '[no change]'
		begin
			UPDATE T_Dataset_Archive
			SET AS_state_ID = @archiveStateID,
				AS_Last_Successful_Archive = 
						CASE WHEN @archiveStateID = 3 
						THEN GETDATE() 
						ELSE AS_Last_Successful_Archive 
						END
			FROM T_Dataset_Archive DA INNER JOIN
				 T_Dataset DS ON DA.AS_Dataset_ID = DS.Dataset_ID
			WHERE (DS.Dataset_Num IN (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end

			If @archiveStateID = 4
			Begin
				-- Dataset(s) marked as purged; update AS_instrument_data_purged to be 1
				-- This field is useful if an analysis job is run on a purged dataset, since, 
				--  when that happens, AS_state_ID will go back to 3=Complete, and we therefore
				--  wouldn't be able to tell if the raw instrument file is available
				UPDATE T_Dataset_Archive
				SET AS_instrument_data_purged = 1
				FROM T_Dataset_Archive DA INNER JOIN
					 T_Dataset DS ON DA.AS_Dataset_ID = DS.Dataset_ID
				WHERE (DS.Dataset_Num IN (SELECT DatasetNum FROM #TDS))
				      AND IsNull(DA.AS_instrument_data_purged, 0) = 0
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
			End
			
			Set @ArchiveStateUpdated = 1
		end

		-----------------------------------------------
		if @updateState <> '[no change]'
		begin
			UPDATE T_Dataset_Archive
			SET AS_update_state_ID = @updateStateID
			FROM T_Dataset_Archive DA INNER JOIN
				 T_Dataset DS ON DA.AS_Dataset_ID = DS.Dataset_ID
			WHERE (DS.Dataset_Num IN (SELECT DatasetNum FROM #TDS))
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Update operation failed'
				rollback transaction @transName
				RAISERROR (@msg, 10, 1)
				return 51004
			end
			
			Set @UpdateStateUpdated = 1
		end
		
		commit transaction @transName


 		If Len(@callingUser) > 0 And (@ArchiveStateUpdated <> 0 Or @UpdateStateUpdated <> 0)
		Begin
			-- @callingUser is defined; call AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log
			--

			-- Populate a temporary table with the list of Dataset IDs just updated
			CREATE TABLE #TmpIDUpdateList (
				TargetID int NOT NULL
			)
			
			CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)
			
			INSERT INTO #TmpIDUpdateList (TargetID)
			SELECT DISTINCT DS.Dataset_ID
			FROM T_Dataset_Archive DA INNER JOIN
				 T_Dataset DS ON DA.AS_Dataset_ID = DS.Dataset_ID
			WHERE (DS.Dataset_Num IN (SELECT DatasetNum FROM #TDS))
			
			If @ArchiveStateUpdated <> 0
				Exec AlterEventLogEntryUserMultiID 6, @archiveStateID, @callingUser
				
			If @UpdateStateUpdated <> 0
				Exec AlterEventLogEntryUserMultiID 7, @updateStateID, @callingUser
		End
		
	end -- update mode

 	---------------------------------------------------
	-- 
	---------------------------------------------------
	
	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateArchiveDatasets] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateArchiveDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateArchiveDatasets] TO [PNL\D3M580] AS [dbo]
GO
