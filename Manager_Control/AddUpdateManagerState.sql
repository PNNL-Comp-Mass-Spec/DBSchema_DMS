/****** Object:  StoredProcedure [dbo].[AddUpdateManagerState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[AddUpdateManagerState]
/****************************************************
**
**	Desc: 
**	Saves and Updates mgractive state values in database
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	jds
**	Date:	03/17/2009
**			04/20/2009 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**    
*****************************************************/
(
	@mode varchar(12) = 'add', -- or 'update' or 'delete'
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	declare @MgrActiveTargetState int
	declare @EventLogUpdateIteration int

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @Mode = 'add'
	begin

		TRUNCATE TABLE T_MgrState
		
		INSERT INTO T_MgrState (MgrID, TypeID, Value)
		SELECT M.M_ID AS ManagerID, PV.TypeID, IsNull(PV.Value, '') AS ParameterValue
		FROM T_Mgrs M
		     INNER JOIN T_ParamValue PV ON M.M_ID = PV.MgrID 
		     INNER JOIN T_ParamType PT ON PV.TypeID = PT.ParamID
		WHERE PT.ParamName = 'mgractive' AND M.M_ControlFromWebsite = 1
		ORDER BY M.M_ID

		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Insert operation failed.'
			RAISERROR (@msg, 10, 1)
			return 51007
		end


	end -- add mode

	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin

		---------------------------------------------------
		-- Create a temporary table that will hold the Entry_ID 
		-- values that need to be updated in T_ParamValue
		---------------------------------------------------
		CREATE TABLE #TmpIDUpdateList (
			TargetID int NOT NULL,
			NewValue varchar(128)
		)
		
		CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

		CREATE TABLE #TmpEntryIDUpdateListSaved (
			Entry_ID int NOT NULL
		)
		
		-- Find the Entry_ID values that need to be updated
		INSERT INTO #TmpIDUpdateList (TargetID, NewValue)
		SELECT PV.Entry_ID, MS.Value
		FROM T_ParamValue PV
		     INNER JOIN T_MgrState MS
		       ON MS.MgrID = PV.MgrID AND
		          MS.TypeID = PV.TypeID
		WHERE IsNull(PV.Value, '') <> MS.Value
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		set @myError = 0
		--

		-- Now actually update the values
		--
		UPDATE T_ParamValue
		SET Value = UL.NewValue
		FROM T_ParamValue PV
		     INNER JOIN #TmpIDUpdateList UL
		       ON PV.Entry_ID = UL.TargetID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Update operation failed.'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		
		If Len(@callingUser) > 0
		Begin -- <a>
			-- @callingUser is defined
			-- Items need to be updated in T_ParamValue	and T_Event_Log	
			
			-- First update T_Param_Value
			Exec AlterEnteredByUserMultiID 'T_ParamValue', 'Entry_ID', @CallingUser, @EntryDateColumnName = 'Last_Affected'


			-- Triggers trig_i_T_ParamValue and trig_u_T_ParamValue make an entry in 
			--  T_Event_Log whenever mgractive (param TypeID = 17) is changed
			
			-- Call AlterEventLogEntryUserMultiID
			-- to alter the Entered_By field in T_Event_Log

			-- We have to do this twice; once for the managers that are enabled and once for the managers that are disabled

			-- First cache the list of Entry_ID values that we just updated 
			-- (since we need to truncate #TmpIDUpdateList and populate it with MgrID values)
			INSERT INTO #TmpEntryIDUpdateListSaved (Entry_ID)
			SELECT TargetID
			FROM #TmpIDUpdateList

			-- Now call AlterEventLogEntryUserMultiID first for managers with mgractive = True, and then for those with mgractive <> True
			Set @EventLogUpdateIteration = 1
			While @EventLogUpdateIteration <= 2
			Begin -- <b>
			
				-- Populate #TmpIDUpdateList with the Manager ID values, then call AlterEventLogEntryUserMultiID
				Truncate Table #TmpIDUpdateList

				If @EventLogUpdateIteration = 1
				Begin
					-- Look for managers with a value of 'True' for 'mgractive'	
					INSERT INTO #TmpIDUpdateList (TargetID)
					SELECT PV.MgrID
					FROM #TmpEntryIDUpdateListSaved UL
					     INNER JOIN T_ParamValue PV
					       ON UL.Entry_ID = PV.Entry_ID
					WHERE PV.Value = 'True'

					Set @MgrActiveTargetState = 1
				End
				Else
				Begin
					-- Look for managers with a value <> 'True' for 'mgractive'
					INSERT INTO #TmpIDUpdateList (TargetID)
					SELECT PV.MgrID
					FROM #TmpEntryIDUpdateListSaved UL
					     INNER JOIN T_ParamValue PV
					       ON UL.Entry_ID = PV.Entry_ID
					WHERE PV.Value <> 'True'

					Set @MgrActiveTargetState = 0
				End

				Exec AlterEventLogEntryUserMultiID 1, @MgrActiveTargetState, @callingUser

				Set @EventLogUpdateIteration = @EventLogUpdateIteration + 1
			End -- </b>
			
		End -- </a>
		
	end -- update mode


	---------------------------------------------------
	-- action for delete mode
	---------------------------------------------------
	--
	if @Mode = 'delete' 
	begin
		set @myError = 0
		--
		TRUNCATE TABLE T_MgrState
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Delete operation failed.'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
	end -- delete mode

	return 0
GO
GRANT EXECUTE ON [dbo].[AddUpdateManagerState] TO [DMSWebUser] AS [dbo]
GO
