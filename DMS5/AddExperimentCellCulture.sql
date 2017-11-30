/****** Object:  StoredProcedure [dbo].[AddExperimentCellCulture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[AddExperimentCellCulture]
/****************************************************
**
**	Desc: Adds cell cultures entries to DB for given experiment
**
**	The calling procedure must create and populate temporary table #Tmp_ExpToCCMap:
**
**		CREATE TABLE #Tmp_ExpToCCMap (
**			CC_Name varchar(128) not null,
**			CC_ID int null
**		)
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	03/27/2002
**			12/21/2009 grk - Commented out requirement that cell cultures belong to same campaign
**			02/20/2012 mem - Now using a temporary table to track the cell culture names in @cellCultureList
**			02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**			03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**			11/29/2017 mem - Remove parameter @cellCultureList and use temporary table #Tmp_ExpToCCMap instead
**			                 Add parameter @updateCachedInfo
**    
*****************************************************/
(
	@expID int,
	@updateCachedInfo tinyint = 1,
	@message varchar(255) = '' output
)
As		
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	If @expID Is Null
	Begin	
		set @message = 'Experiment ID cannot be null'
		return 51061
	End
	
	Set @updateCachedInfo = IsNull(@updateCachedInfo, 1)
	Set @message = ''
	
	---------------------------------------------------
	-- Try to resolve any null cell culture ID values in #Tmp_ExpToCCMap
	---------------------------------------------------
	--
	UPDATE #Tmp_ExpToCCMap
	SET CC_ID = Src.CC_ID
	FROM #Tmp_ExpToCCMap Target
	     INNER JOIN T_Cell_Culture Src
	       ON Src.CC_Name = Target.CC_Name
	WHERE Target.CC_ID Is Null
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	---------------------------------------------------
	-- Look for invalid entries in #Tmp_ExpToCCMap
	---------------------------------------------------
	--
	Declare @invalidCCList varchar(512) = null

	SELECT @invalidCCList = Coalesce(@invalidCCList + ', ' + CC_Name, CC_Name)
	FROM #Tmp_ExpToCCMap
	WHERE CC_ID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If Len(IsNull(@invalidCCList, '')) > 0
	Begin
		Set @message = 'Invalid cell culture name(s): ' + @invalidCCList
		return 51063
	End

	---------------------------------------------------
	-- Add/remove cell culture items
	---------------------------------------------------
	--
	DELETE T_Experiment_Cell_Cultures
	WHERE Exp_ID = @expID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	INSERT INTO T_Experiment_Cell_Cultures (Exp_ID, CC_ID)
	SELECT DISTINCT @expID as Exp_ID, CC_ID
	FROM #Tmp_ExpToCCMap
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error updating cell culture mapping for experiment ' + Cast(@expID as varchar(9))
		return 51062
	end

	---------------------------------------------------
	-- Optionally update T_Cached_Experiment_Components
	---------------------------------------------------
	--
	If @updateCachedInfo > 0
	Begin
		Exec UpdateCachedExperimentComponentNames @expID
	End
		
	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentCellCulture] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddExperimentCellCulture] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddExperimentCellCulture] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddExperimentCellCulture] TO [Limited_Table_Write] AS [dbo]
GO
