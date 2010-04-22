/****** Object:  StoredProcedure [dbo].[DoMaterialItemOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoMaterialItemOperation
/****************************************************
**
**  Desc: 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**			10/01/2009 mem - Expanded error message
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
	@name varchar(128),
	@mode varchar(32),					-- 'retire_biomaterial', 'retire_experiment'
    @message varchar(512) output,
	@callingUser varchar (128) = ''
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
    declare @msg varchar(512)

	---------------------------------------------------
	-- convert name to ID
	---------------------------------------------------
	declare @tmpID int
	set @tmpID = 0
	--
	declare @type_tag varchar(2)
	set @type_tag = ''
	--

	if @mode = 'retire_biomaterial'
	begin
		-- look up ID from name from cell culture
		set @type_tag = 'B'
		--
		SELECT @tmpID = CC_ID
		FROM T_Cell_Culture
		WHERE CC_Name = @name	
	end
	if @mode = 'retire_experiment'
	begin
		-- look up ID from name from experiment
		set @type_tag = 'E'
		--
		SELECT @tmpID = Exp_ID
		FROM T_Experiments
		WHERE Experiment_Num = @name
	end
	
	---------------------------------------------------
	-- call the material update function
	---------------------------------------------------
	--
	if @tmpID = 0
	begin
		set @msg = 'Could not find the material item for @mode="' + @mode + '" and @name="' + @name + '"'
		RAISERROR (@msg, 10, 1)
		return 51010
	end
	else
	begin
		declare 
			@iMode varchar(32), -- 'move_material', 'retire_items'
			@itemList varchar(4096),
			@itemType varchar(128), -- 'mixed_material', 'containers'
			@newValue varchar(128),
			@comment varchar(512)

			set @iMode = 'retire_items'
			set @itemList  = @type_tag + ':' + convert(varchar, @tmpID)
			set @itemType  = 'mixed_material'
			set @newValue  = ''
			set @comment  = ''

		exec @myError = UpdateMaterialItems
				@iMode, -- 'move_material', 'retire_items'
				@itemList,
				@itemType, -- 'mixed', 'containers'
				@newValue,
				@comment,
				@message output,
   				@callingUser
		
		if @myError <> 0
		begin
			set @msg = 'xx'
			RAISERROR (@msg, 10, 1)
			return @myError
		end
	end


GO
GRANT EXECUTE ON [dbo].[DoMaterialItemOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialItemOperation] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialItemOperation] TO [PNL\D3M580] AS [dbo]
GO
