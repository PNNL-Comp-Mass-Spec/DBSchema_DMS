/****** Object:  StoredProcedure [dbo].[DoCellCultureOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoCellCultureOperation
/****************************************************
**
**	Desc: 
**		Perform cell cluture operation defined by 'mode'
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 6/17/2002
**    
*****************************************************/
(
	@cellCulture varchar(128),
	@mode varchar(12), -- 'delete'
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @result int

	---------------------------------------------------
	-- get cell culture ID 
	---------------------------------------------------

	declare @ccID int
	set @ccID = 0
	--
	SELECT  
		@ccID = CC_ID
	FROM T_Cell_Culture 
	WHERE (CC_Name = @cellCulture)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @ccID = 0
	begin
		set @message = 'Could not get Id for cell cluture "' + @cellCulture + '"'
		RAISERROR (@message, 10, 1)
		return 51140
	end

	---------------------------------------------------
	-- Delete cell cluture if it is in "new" state only
	---------------------------------------------------

	if @mode = 'delete'
	begin
		---------------------------------------------------
		-- verify that cell cluture is not used by any experiments
		---------------------------------------------------

		declare @exps int
		set @exps = 1
		--
		SELECT @exps = COUNT(*)
		FROM  T_Experiment_Cell_Cultures
		WHERE  (CC_ID = @ccID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to count experiment references'
			RAISERROR (@message, 10, 1)
			return 51141
		end
		--
		if @exps > 0
		begin
			set @message = 'Cannot delete cell culture that is referenced by any experiments'
			RAISERROR (@message, 10, 1)
			return 51141
		end
		
		---------------------------------------------------
		-- delete the cell cluture
		---------------------------------------------------
		
		DELETE FROM T_Cell_Culture
		WHERE CC_ID = @ccID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			RAISERROR ('Could not delete cell cluture "%s"',
				10, 1, @cellCulture)
			return 51142
		end

		return 0
	end -- mode 'delete'
		
	---------------------------------------------------
	-- Mode was unrecognized
	---------------------------------------------------
	
	set @message = 'Mode "' + @mode +  '" was unrecognized'
	RAISERROR (@message, 10, 1)
	return 51222

GO
