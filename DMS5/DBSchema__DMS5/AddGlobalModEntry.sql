/****** Object:  StoredProcedure [dbo].[AddGlobalModEntry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddGlobalModEntry
/****************************************************
**
**	Desc: Adds a new or updates an existing global modification
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		@paramFileName  name of new param file description
**		@paramFileDesc  description of paramfileentry 
**	
**
**		Auth: kja
**		Date: 08/02/2004
**    
*****************************************************/
(
	@modSymbol char(8), 
	@modDescription varchar(64),
	@modType char(1), 
	@modMassChange float(8),
	@modResidues varchar(50),
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	set @myError = 0
	if LEN(@modSymbol) < 1
	begin
		set @myError = 51000
		RAISERROR ('modSymbol was blank',
			10, 1)
	end

	--

	if LEN(@modDescription) < 1
	begin
		set @myError = 51001
		RAISERROR ('modDescription was blank',
			10, 1)
	end
	
	--
	
	if @modType <> 'S' and @modType <> 'D'
	begin
		set @myError = 51002
		RAISERROR ('modType must be S or D',
			10, 1)
	end
	
--
	
	if @myError <> 0
		return @myError

	---------------------------------------------------
	-- Is entry already in database?
	---------------------------------------------------

	declare @ModID int
	set @ModID = 0
	--
	execute @ModID = GetGlobalModID @modMassChange, @modType, @modResidues
	
	-- cannot create an entry that already exists

	if @ModID <> 0
	begin
		set @msg = 'Cannot Add: Symbol "' + @modSymbol + '" already exists'
		RAISERROR (@msg, 10, 1)
		return 51004
	end
	
	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'AddGlobalMod'
	begin transaction @transName


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------

	begin

		INSERT INTO T_Peptide_Mod_Global_List (
			Symbol,
			Description,
			SD_Flag,
			Mass_Correction_Factor,
			Affected_Residues
		) VALUES (
			@modSymbol, 
			@modDescription, 
			@modType, 
			Round(@modMassChange,4), 
			@modResidues
		)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Insert operation failed: "' + @modSymbol + '"'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end


	commit transaction @transName

	return 0

GO
GRANT EXECUTE ON [dbo].[AddGlobalModEntry] TO [MTS_SP_User]
GO
GRANT EXECUTE ON [dbo].[AddGlobalModEntry] TO [RBAC-Web_Analysis]
GO
