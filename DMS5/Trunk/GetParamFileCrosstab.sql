/****** Object:  StoredProcedure [dbo].[GetParamFileCrosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.GetParamFileCrosstab
/****************************************************
** 
**	Desc:	Returns a crosstab table displaying modification details
**			by Sequset or X!Tandem parameter file
**		
**	Return values: 0: success, otherwise, error code
** 
**	Date:	12/05/2006 mem - Initial version (Ticket #337)
**			12/11/2006 mem - Renamed from GetSequestParamFileCrosstab to GetParamFileCrosstab (Ticket #342)
**						   - Added parameters @ParameterFileTypeName and @ShowValidOnly
**						   - Updated to call PopulateParamFileInfoTableSequest and PopulateParamFileModInfoTable 
**			04/07/2008 mem - Added parameters @previewSql, @MassModFilterTextColumn, and @MassModFilterText
**			05/19/2009 mem - Now returning column Job_Usage_Count
**			02/12/2010 mem - Expanded @ParameterFileFilter to varchar(255)
**    
*****************************************************/
(
	@ParameterFileTypeName varchar(64) = 'Sequest',		-- Should be 'Sequest' or 'XTandem'
	@ParameterFileFilter varchar(255) = '',				-- Optional parameter file name filter
	@ShowValidOnly tinyint = 0,							-- Set to 1 to only show "Valid" parameter files
	@ShowModSymbol tinyint = 0,							-- Set to 1 to display the modification symbol
	@ShowModName tinyint = 1,							-- Set to 1 to display the modification name
	@ShowModMass tinyint = 1,							-- Set to 1 to display the modification mass
	@UseModMassAlternativeName tinyint = 1,
	@message varchar(512) = '' output,
	@previewSql tinyint = 0,
	@MassModFilterTextColumn varchar(64) = '',			-- If text is defined here, then the @MassModFilterText filter is only applied to column(s) whose name matches this
	@MassModFilterText varchar(64) = ''					-- If text is defined here, then results are filtered to only show rows that contain this text in one of the mass mod columns
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @ParamFileInfoColumnList varchar(512)
	Set @ParamFileInfoColumnList = ''

	Declare @S varchar(max)
	Declare @MassModFilterSql varchar(4000)
	
	Set @S = ''
	Set @MassModFilterSql = ''

	Declare @AddWildcardChars tinyint
	Set @AddWildcardChars = 1
	
	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	Set @ParameterFileTypeName = IsNull(@ParameterFileTypeName, 'Sequest')
	Set @ParameterFileFilter = IsNull(@ParameterFileFilter, '')
	Set @ShowValidOnly = IsNull(@ShowValidOnly, 0)
	Set @ShowModSymbol = IsNull(@ShowModSymbol, 0)
	Set @ShowModName = IsNull(@ShowModName, 1)
	Set @ShowModMass = IsNull(@ShowModMass, 1)
	Set @UseModMassAlternativeName = IsNull(@UseModMassAlternativeName, 1)
	Set @message = ''
	Set @previewSql = IsNull(@previewSql, 0)
	Set @MassModFilterTextColumn = IsNull(@MassModFilterTextColumn, '')
	Set @MassModFilterText = IsNull(@MassModFilterText, '')
	
	-- Make sure @ParameterFileTypeName is of a known type
	If @ParameterFileTypeName <> 'Sequest' and @ParameterFileTypeName <> 'XTandem'
	Begin
		Set @message = 'Unknown parameter file type: ' + @ParameterFileTypeName + '; should be Sequest or XTandem'
		Set @myError = 50000
		Goto Done
	End
	
	If Len(@ParameterFileFilter) > 0
	Begin
		If @AddWildcardChars <> 0
			If CharIndex('%', @ParameterFileFilter) = 0
				Set @ParameterFileFilter = '%' + @ParameterFileFilter + '%'
	End
	Else
		Set @ParameterFileFilter = '%'

	-- Assure that one of the following is non-zero
	If @ShowModSymbol = 0 AND @ShowModName = 0 AND @ShowModMass = 0 
		Set @ShowModName = 1


	-----------------------------------------------------------
	-- Create some temporary tables
	-----------------------------------------------------------

	CREATE TABLE #TmpParamFileInfo (
		Param_File_ID Int NOT NULL,
		Date_Created datetime NULL,
		Date_Modified datetime NULL,
		Job_Usage_Count int NULL
	)
	CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ParamFileInfo_Param_File_ID ON #TmpParamFileInfo(Param_File_ID)

	CREATE TABLE #TmpParamFileModResults (
		Param_File_ID int
	)
	CREATE UNIQUE INDEX #IX_TempTable_TmpParamFileModResults_Param_File_ID ON #TmpParamFileModResults(Param_File_ID)

	-----------------------------------------------------------
	-- Populate a temporary table with the parameter files
	-- matching @ParameterFileFilter
	-----------------------------------------------------------

	INSERT INTO #TmpParamFileInfo (Param_File_ID, Date_Created, Date_Modified, Job_Usage_Count)
	SELECT PF.Param_File_ID, PF.Date_Created, PF.Date_Modified, PF.Job_Usage_Count
	FROM T_Param_File_Types PFT INNER JOIN
		 T_Param_Files PF ON PFT.Param_File_Type_ID = PF.Param_File_Type_ID
	WHERE PFT.Param_File_Type = @ParameterFileTypeName AND 
		  (PF.Valid = 1 OR @ShowValidOnly = 0) AND 
		  PF.Param_File_Name LIKE @ParameterFileFilter
	--	  
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error finding matching parameter files: ' + Convert(varchar(19), @myError)
		goto done
	end

	-----------------------------------------------------------
	-- Possibly append some additional columns to #TmpParamFileInfo,
	--  to be included at the beginning of the crosstab report
	-----------------------------------------------------------
	
	If @ParameterFileTypeName = 'Sequest'
	Begin
		Exec @myError = PopulateParamFileInfoTableSequest
								@ParamFileInfoColumnList = @ParamFileInfoColumnList output, 
								@message = @message output
		If @myError <> 0
			Goto Done
	End

	-----------------------------------------------------------
	-- Populate #TmpParamFileModResults
	-----------------------------------------------------------
	Exec @myError = PopulateParamFileModInfoTable	@ShowModSymbol, @ShowModName, @ShowModMass, 
													@UseModMassAlternativeName, 
													@MassModFilterTextColumn,
													@MassModFilterText,
													@MassModFilterSql = @MassModFilterSql output,
													@message = @message output
	If @myError <> 0
		Goto Done

	-----------------------------------------------------------
	-- Return the results
	-----------------------------------------------------------
	Set @S = ''
	Set @S = @S + ' SELECT PF.Param_File_Name, PF.Param_File_Description, PF.Job_Usage_Count, '
	
	If Len(IsNull(@ParamFileInfoColumnList, '')) > 0
		Set @S = @S +      @ParamFileInfoColumnList + ', '
	
	Set @S = @S +        ' PFMR.*,'
	Set @S = @S +        ' PF.Date_Created, PF.Date_Modified, PF.Valid'
	Set @S = @S + ' FROM #TmpParamFileInfo PFI INNER JOIN'
	Set @S = @S +    ' T_Param_Files PF ON PFI.Param_File_ID = PF.Param_File_ID LEFT OUTER JOIN'
	Set @S = @S +    ' #TmpParamFileModResults PFMR ON PFI.Param_File_ID = PFMR.Param_File_ID'
	
	If Len(@MassModFilterSql) > 0
		Set @S = @S + ' WHERE ' + @MassModFilterSql

	Set @S = @S + ' ORDER BY PF.Param_File_Name'
	
	If @previewSql <> 0
		Print @S
	Else
		Exec (@S)
	--	  
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error returning the results: ' + Convert(varchar(19), @myError)
		goto done
	end
	
	-----------------------------------------------------------
	-- Exit
	-----------------------------------------------------------
Done:
	return @myError


GO
GRANT EXECUTE ON [dbo].[GetParamFileCrosstab] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetParamFileCrosstab] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileCrosstab] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetParamFileCrosstab] TO [PNL\D3M580] AS [dbo]
GO
