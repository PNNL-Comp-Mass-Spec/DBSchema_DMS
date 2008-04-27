/****** Object:  StoredProcedure [dbo].[AddUpdateParamFileEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddUpdateParamFileEntry
/****************************************************
**
**	Desc: Adds new or updates existing parameter file entry in database
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@paramFileID  name of new param file description
**		@entryType  description of paramfileentry 
**		@entrySpecifier
**	    @entryValue
**
**	Auth:	kja
**	Date:	07/22/2004
**			08/10/2004 kja - Added in code to update mapping table as well
**			03/25/2008 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**    
*****************************************************/
(
	@paramFileID int,
	@entrySeqOrder int,
	@entryType varchar(32), 
	@entrySpecifier varchar(32),
	@entryValue varchar(32),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if @paramFileID = 0
	begin
		set @myError = 51000
		RAISERROR ('ParamFileID was blank',
			10, 1)
	end
	
	--

	if @entrySeqOrder = 0
	begin
		set @myError = 51001
		RAISERROR ('EntrySeqOrder was blank',
			10, 1)
	end
	
	--

	if LEN(@entryType) < 1
	begin
		set @myError = 51001
		RAISERROR ('EntryType was blank',
			10, 1)
	end

	--
		if LEN(@entrySpecifier) < 1
	begin
		set @myError = 51001
		RAISERROR ('EntrySpecifier was blank',
			10, 1)
	end

	--

		if LEN(@entryValue) < 1
	begin
		set @myError = 51001
		RAISERROR ('EntryValue was blank',
			10, 1)
	end

	--

	if @myError <> 0
		return @myError
		
	---------------------------------------------------
	-- Detour if Mass mod
	---------------------------------------------------
	
	declare @transName varchar(32)

	if ((@entryType = 'DynamicModification') OR (@entryType = 'StaticModification') OR (@entryType = 'IsotopicModification'))
	begin
		declare @localSymbolID int
		declare @typeSymbol char(1)
		declare @affectedResidue char(1)
		declare @affectedResidueID int
		declare @massCorrectionID int
		
		if (@entryType = 'StaticModification')
		begin
			set @localSymbolID = 0
			set @typeSymbol = 'S'
			set @affectedResidue = @entrySpecifier
		end
		
		if (@entryType = 'IsotopicModification')
		begin
			set @localSymbolID = 0
			set @typeSymbol = 'I'
			set @affectedResidueID = 1
		end
		
		if (@entryType = 'DynamicModification')
		begin
			execute @localSymbolID = GetNextLocalSymbolID @ParamFileID
			set @typeSymbol = 'D'
		end
		
		set @transName = 'AddMassModEntry'
		begin transaction @transName
		
		declare @counter int
		set @counter = 0
		
		execute @massCorrectionID = GetMassCorrectionID @entryValue

		
		while @counter < len(@entryspecifier)

		begin

			set @counter = @counter + 1
						
			if (@entryType = 'StaticModification') AND @counter < 2
			begin
				if len(@entrySpecifier) > 1  -- Then the mod is a terminal mod
				begin
					if @entrySpecifier = 'N_Term_Protein'
					begin
						set @affectedResidue = '['
						set @typeSymbol = 'P'
					end
					
					if @entrySpecifier = 'C_Term_Protein'
					begin
						set @affectedResidue = ']'
						set @typeSymbol = 'P'
					end
					
					if @entrySpecifier = 'N_Term_Peptide'
					begin
						set @affectedResidue = '<'
						set @typeSymbol = 'T'
					end
					
					if @entrySpecifier = 'C_Term_Peptide'
					begin
						set @affectedResidue = '>'
						set @typeSymbol = 'T'
					end
				end
			execute @affectedResidueID = GetResidueID @affectedResidue
			end
			else
				if (@entryType = 'StaticModification') AND @counter > 1
					break
			
		
			if @entryType = 'DynamicModification'
			begin
				set @affectedResidue = substring(@entrySpecifier, @counter, 1)
				execute @affectedResidueID = GetResidueID @affectedResidue
			end				
		
				INSERT INTO T_Param_File_Mass_Mods (
				Residue_ID,
				Local_Symbol_ID,
				Mass_Correction_ID,
				Param_File_ID,
				Mod_Type_Symbol
			) VALUES (
				@affectedResidueID,
				@localSymbolID, 
				@massCorrectionID, 
				@paramFileID,
				@typeSymbol
			)
			
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @msg = 'Insert operation failed: "' + cast(@ParamfileID as varchar) + '"'
				RAISERROR (@msg, 10, 1)
				return 51007
			end
			
			if @@error <> 0
			begin
				rollback transaction @transname
				RAISERROR ('Update to global mod mapping table was unsuccessful for param file', 
					10, 1)
			end

		end	
		commit transaction @transname
			
		return 0
	end
		
	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @ParamEntryID int
	set @ParamEntryID = 0
	--
	execute @ParamEntryID = GetParamEntryID @ParamFileID, @EntryType, @EntrySpecifier, @EntrySeqOrder
	
	
	if @ParamEntryID <> 0
	begin
		set @mode = 'update'
	end
	
	-- cannot create an entry that already exists
	--
	if @ParamEntryID <> 0 and @mode = 'add'
	begin
		set @msg = 'Cannot add: Param Entry "' + @ParamEntryID + '" already in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	-- cannot update a non-existent entry
	--
	if @ParamFileID = 0 and @mode = 'update'
	begin
		set @msg = 'Cannot update: Param Entry "' + @ParamEntryID + '" is not in database '
		RAISERROR (@msg, 10, 1)
		return 51004
	end

	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	
	set @transName = 'AddParamEntries'
	begin transaction @transName

	
	if @Mode = 'add'
	begin

		INSERT INTO T_Param_Entries (
			Entry_Sequence_Order, 
			Entry_Type, 
			Entry_Specifier, 
			Entry_Value, 
			Param_File_ID
		) VALUES (
			@entrySeqOrder, 
			@entryType, 
			@entrySpecifier, 
			@entryValue,  
			@paramFileID
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transname
			RAISERROR ('Addition to param entry table was unsuccessful for param file',
				10, 1)
			return 51131
		end

		Set @ParamEntryID = IDENT_CURRENT('T_Param_Entries')
		
		-- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processor_Group
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Param_Entries', 'Param_Entry_ID', @ParamEntryID, @CallingUser

	end -- add mode
	
	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
	--
	if @Mode = 'update' 
	begin
		set @myError = 0
		--
		UPDATE T_Param_Entries 
		SET 
			Entry_Specifier = @entrySpecifier,
			Entry_Value = @entryValue
		WHERE (Param_Entry_ID = @ParamEntryID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transname
			RAISERROR ('Update to param entry table was unsuccessful for param file',
				10, 1)
			return 51131
		end
		
		-- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processor_Group
		If Len(@callingUser) > 0
			Exec AlterEnteredByUser 'T_Param_Entries', 'Param_Entry_ID', @ParamEntryID, @CallingUser

	end -- update mode

	commit transaction @transname

	return 0

GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFileEntry] TO [DMS_ParamFile_Admin]
GO
