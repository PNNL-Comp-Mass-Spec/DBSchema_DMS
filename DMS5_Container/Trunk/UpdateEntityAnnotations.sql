/****** Object:  StoredProcedure [dbo].[UpdateEntityAnnotations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateEntityAnnotations]
/****************************************************
**
**	Desc: 
**    Sets the values of annotation parameters 
**    for a set of DMS tracking entities according to
**    contents of XML file
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date: 	05/03/2007 (only does experiment annotations at present)
**			09/02/2011 mem - Now calling PostUsageLogEntry
**    
*****************************************************/
(
	@xmlDoc varchar(4000),
	@entityType varchar(24) = 'experiment', -- 'campaign', 'experiment', 'dataset', 'analysis job'
	@mode varchar(24) = 'InfoOnly', -- 'InfoOnly', 'DeleteOnly', 'Update'
    @message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	Declare @EntityCount int = 0

	---------------------------------------------------
	--  Create temporary table to hold list of tracking entities
	---------------------------------------------------
 
 	CREATE TABLE #TENT (
		entID int
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary parameter table'
		goto DONE
	end

	---------------------------------------------------
	--  Create temporary table to hold list of parameters
	---------------------------------------------------
 
 	CREATE TABLE #TPAR (
		paramName varchar(128),
		paramValue varchar(512)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to create temporary parameter table'
		goto DONE
	end
	
	---------------------------------------------------
	-- Parse the XML input
	---------------------------------------------------
	DECLARE @hDoc int
	EXEC sp_xml_preparedocument @hDoc OUTPUT, @xmlDoc

 	---------------------------------------------------
	-- Populate tracking entity table from XML   
	---------------------------------------------------

	INSERT INTO #TENT
	(entID)
	SELECT * FROM OPENXML(@hDoc, N'//Entity')  with ([ID] int)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary entity table'
		goto DONE
	end

	Set @EntityCount = @myRowCount

 	---------------------------------------------------
	-- Populate parameter table from XML parameter description  
	---------------------------------------------------

	INSERT INTO #TPAR
	(paramName, paramValue)
	SELECT * FROM OPENXML(@hDoc, N'//Parameter')  with ([Name] varchar(128), [Value] varchar(512))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating temporary parameter table'
		goto DONE
	end
    
 	---------------------------------------------------
	-- Remove the internal representation of the XML document.
 	---------------------------------------------------
 	
	EXEC sp_xml_removedocument @hDoc

	---------------------------------------------------
	-- Trap "information only" mode here
	---------------------------------------------------
	if @mode = 'InfoOnly'
	begin
		SELECT * FROM T_Experiment_Annotations
		WHERE Experiment_ID IN (SELECT entID FROM #TENT) AND Key_Name IN (SELECT paramName FROM #TPAR)
		--
		SELECT entID, paramName, paramValue FROM #TENT CROSS JOIN #TPAR
		goto DONE
	end

 	---------------------------------------------------
	-- Remove existing annotation parameters 
	-- for set of tracking entities
	---------------------------------------------------

	DELETE FROM T_Experiment_Annotations
	WHERE Experiment_ID IN (SELECT entID FROM #TENT) AND Key_Name IN (SELECT paramName FROM #TPAR)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error clearing parameters'
		goto DONE
	end

	---------------------------------------------------
	-- Trap "delete only" mode here
	---------------------------------------------------
	if @mode = 'DeleteOnly'
		goto DONE
	
	---------------------------------------------------
	-- Verify 'Update' mode here
	---------------------------------------------------
	if @mode <> 'Update'
		goto DONE

 	---------------------------------------------------
	-- Insert new annotation parameters 
	-- for set of tracking entities
	---------------------------------------------------

	INSERT INTO T_Experiment_Annotations
     (Experiment_ID, Key_Name, Value)
	SELECT entID, paramName, paramValue FROM #TENT CROSS JOIN #TPAR
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating parameters'
		goto DONE
	end
     
DONE:

	---------------------------------------------------
	-- Log SP usage
	---------------------------------------------------

	Declare @UsageMessage varchar(512)
	Set @UsageMessage = 'Updated ' + Convert(varchar(12), @EntityCount) + ' ' + IsNull(@entityType, '??')
	If @EntityCount <> 1
		Set @UsageMessage = @UsageMessage + 's'
	Exec PostUsageLogEntry 'UpdateEntityAnnotations', @UsageMessage

	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateEntityAnnotations] TO [DMS_Annotation_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEntityAnnotations] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEntityAnnotations] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEntityAnnotations] TO [PNL\D3M580] AS [dbo]
GO
