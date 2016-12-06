/****** Object:  StoredProcedure [dbo].[AddExperimentCellCulture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure AddExperimentCellCulture
/****************************************************
**
**	Desc: Adds cell cultures entries to DB for
**        given experiment
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**	Date:	03/27/2002
**			12/21/2009 grk - commented out requirement that cell cultures belong to same campaign
**			02/20/2012 mem - Now using a temporary table to track the cell culture names in @cellCultureList
**			02/22/2012 mem - Switched to using a table-variable instead of a physical temporary table
**    
*****************************************************/
(
	@expID int,
	@cellCultureList varchar(200) = Null,			-- semi-colon separated list of cell culture names to associate with @expID
	@message varchar(255) = '' output
)
As		
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @done int
	declare @count int
	
	declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------

	If @expID Is Null
	Begin	
		set @message = 'Experiment ID cannot be null'
		return 51061
	End
	
	Set @cellCultureList = IsNull(@cellCultureList, '')
	Set @message = ''
	
	---------------------------------------------------
	-- Parse @cellCultureList to determine cell culture names
	---------------------------------------------------

	Declare @tblCellCulture Table (
		CellCultureName varchar(128)
	)
	
	INSERT INTO @tblCellCulture (CellCultureName)
	SELECT Value
	FROM dbo.udfParseDelimitedList(@cellCultureList, ';')
	WHERE Len(Value) > 0
	ORDER BY Value


	-- Look for invalid entries in @tblCellCulture
	Declare @UnknownNames varchar(512) = ''

	SELECT @UnknownNames = @UnknownNames + TCC.CellCultureName + ', '
	FROM @tblCellCulture TCC
	     LEFT OUTER JOIN T_Cell_Culture CC
	       ON TCC.CellCultureName = CC.CC_Name
	WHERE CC.CC_Name IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If Len(IsNull(@UnknownNames, '')) > 0
	Begin
		-- Remove the trailing comma
		Set @UnknownNames = Substring(@UnknownNames, 1, Len(@UnknownNames) - 1)
		
		set @message = 'Cell culture name could not be found: ' + @UnknownNames
		return 51063
	End
	
	
	---------------------------------------------------
	-- Delete any existing entries from T_Experiment_Cell_Cultures
	---------------------------------------------------
	--
	DELETE FROM T_Experiment_Cell_Cultures
	WHERE (Exp_ID = @expID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Delete was unsuccessful for experiment cell culture table'
		return 51060
	end

	---------------------------------------------------
	-- Add new entries to T_Experiment_Cell_Cultures
	---------------------------------------------------
	--
	INSERT INTO T_Experiment_Cell_Cultures (Exp_ID, CC_ID)
	SELECT @expID as ExperimentID, CC.CC_ID
	FROM @tblCellCulture TCC
	     INNER JOIN T_Cell_Culture CC
	       ON TCC.CellCultureName = CC.CC_Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Insert was unsuccessful for experiment cell culture table'
		return 51062
	end
	
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
