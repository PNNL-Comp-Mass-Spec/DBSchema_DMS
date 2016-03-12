/****** Object:  StoredProcedure [dbo].[DeleteAuxInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure DeleteAuxInfo
/****************************************************
**
**	Desc: 
**		Deletes existing auxiliary information in database
**		for given target type and identity
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: grk
**		Date: 4/8/2002
**    
*****************************************************/
(
	@targetName varchar(128) = '',
	@targetEntityName varchar(128) = '',
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
		
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future

	---------------------------------------------------
	-- Resolve target name to target table criteria
	---------------------------------------------------

	declare @tgtTableName varchar(128)
	declare @tgtTableNameCol varchar(128)
	declare @tgtTableIDCol varchar(128)

	SELECT 
		@tgtTableName = Target_Table, 
		@tgtTableIDCol = Target_ID_Col, 
		@tgtTableNameCol = Target_Name_Col
	FROM T_AuxInfo_Target
	WHERE (Name = @targetName)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @message = 'Could not look up table criteria for target: "' + @targetName + '"'
		return 51000
	end

	---------------------------------------------------
	-- Resolve target name and entity name to entity ID
	---------------------------------------------------

	declare @targetID int
	set @targetID = 0
	
	declare @sql nvarchar(1024)
	
	set @sql = N'' 
	set @sql = @sql + 'SELECT @targetID = ' + @tgtTableIDCol
	set @sql = @sql + ' FROM ' + @tgtTableName
	set @sql = @sql + ' WHERE ' + @tgtTableNameCol
	set @sql = @sql + ' = ''' + @targetEntityName + ''''
	
	exec sp_executesql @sql, N'@targetID int output', @targetID = @targetID output

	if @targetID = 0
	begin
		set @message = 'Error resolving ID for ' + @targetName + ' "' + @targetEntityName + '"'
		return 51000
	end


	---------------------------------------------------
	-- Delete all entries from auxiliary value table
	-- for the given target type and identity
	---------------------------------------------------

	DELETE FROM T_AuxInfo_Value
	WHERE (Target_ID = @targetID) AND 
	(
		AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_Aux_Info_Definition_wID
		WHERE (Target = @targetName)
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error deleting auxiliary info for ' + @targetName + ' "' + @targetEntityName + '"'
		return 51000
	end

	return 0
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAuxInfo] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAuxInfo] TO [PNL\D3M578] AS [dbo]
GO
