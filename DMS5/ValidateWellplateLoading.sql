/****** Object:  StoredProcedure [dbo].[ValidateWellplateLoading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ValidateWellplateLoading
/****************************************************
**
**	Desc: 
**    Checks to see if given set of consecutive well
**    loadings for a given wellplate are valid
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	07/24/2009
**			07/24/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/741)
**			11/30/2009 grk - fixed problem with filling last well causing error message
**			12/01/2009 grk - modified to skip checking of existing well occupancy if @totalCount = 0
**    
*****************************************************/
(
	@wellplateNum varchar(64) output,
	@wellNum varchar(8) output,
	@totalCount int,                    -- Number of consecutive wells to be filled
	@wellIndex int output,				-- index position of wellNum
	@message varchar(512) output
)
AS
	SET NOCOUNT ON
	declare @myError int
	set @myError = 0
	declare @myRowCount int

	---------------------------------------------------
	-- normalize wellplate values
	---------------------------------------------------

	-- normalize values meaning 'empty' to null
	--
	if @wellplateNum = '' or @wellplateNum = 'na'
	begin
		set @wellplateNum = null
	end
	if @wellNum = '' or @wellNum = 'na'
	begin
		set @wellNum = null
	end
	set @wellNum = upper(@wellNum)

	-- make sure that wellplate and well values are consistent 
	-- with each other
	--
	if (@wellNum is null and not @wellplateNum is null) or (not @wellNum is null and @wellplateNum is null) 
	begin
		set @message = 'Wellplate and well must either both be empty or both be set'
		return 51042
	end
	
	---------------------------------------------------
	-- get wellplate index
	---------------------------------------------------
	--
	set @wellIndex = 0
	--
	-- check for overflow
	--
	if not @wellNum is null
	begin
		set @wellIndex = dbo.GetWellIndex(@wellNum)		
		if @wellIndex = 0
		begin
			set @message = 'Well number is not valid'
			return 51043
		end
		--
		if @wellIndex + @totalCount > 97 -- index is first new well, which understates available space by one
		begin
			set @message = 'Wellplate capacity would be exceeded'
			return 51044
		end
	end

	---------------------------------------------------
	-- make sure wells are not in current use
	---------------------------------------------------
	-- don't bother if we are not adding new item
	IF @totalCount = 0 GOTO Done
	--
	declare @wells TABLE (
		wellIndex int
	)
	declare @index int
	declare @count smallint
	set @count = @totalCount
	set @index = @wellIndex
	while @count > 0
	begin
		insert into @wells (wellIndex) values (@index)
		set @count = @count - 1
		set @index = @index + 1
	end 
	--
	declare @hits int
	DECLARE @wellList VARCHAR(8000)
	--
	SET @wellList = ''
	set @hits = 0
	SELECT
		@hits = @hits + 1, 
		@wellList = CASE WHEN @wellList = '' THEN EX_well_num ELSE ', ' + EX_well_num END
	FROM T_Experiments
	WHERE
		EX_wellplate_num = @wellplateNum AND 
		dbo.GetWellIndex(EX_well_num) IN (
			select wellIndex 
			from @wells
		)
	if @hits > 0
	begin
		SET @wellList = SUBSTRING(@wellList, 0, 256)
		IF @hits = 1
			set @message = 'Well ' + @wellList + ' on wellplate "' + @wellplateNum + '" is currently filled'
		else
			set @message = 'Wells ' + @wellList + ' on wellplate "' + @wellplateNum + '" are currently filled'
		return 51045
	end

	---------------------------------------------------
	-- OK
	---------------------------------------------------
Done:
	return @myError
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateWellplateLoading] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateWellplateLoading] TO [PNL\D3M578] AS [dbo]
GO
