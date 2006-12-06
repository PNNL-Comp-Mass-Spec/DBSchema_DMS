/****** Object:  StoredProcedure [dbo].[GetSequestParamFileCrosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.GetSequestParamFileCrosstab
/****************************************************
** 
**	Desc:	Returns a crosstab table displaying modification details
**			by Sequest parameter file
**		
**	Return values: 0: success, otherwise, error code
** 
**	Date:	12/05/2006 mem - Initial version (Ticket #337)
**    
*****************************************************/
(
	@ParameterFileFilter varchar(128) = '',			-- Optional parameter file name filter
	@AddWildcardChars tinyint = 1,					-- If 1, then adds percent signs to the beginning and end of @ParameterFileFilter if it does not contain a percent sign
	@ShowModSymbol tinyint = 1,						-- Set to 1 to display the modification symbol
	@ShowModName tinyint = 1,						-- Set to 1 to display the modification name
	@ShowModMass tinyint = 0,						-- Set to 1 to display the modification mass
	@UseModMassAlternativeName tinyint = 0,
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @ParameterFileTypeName varchar(64)
	Set @ParameterFileTypeName = 'Sequest'

	Declare @CurrentColumn varchar(64)
	Declare @ColumnHeaderRowID int
	Declare @ContinueColumnHeader int
	Declare @ContinueAppendDescriptions int
	Declare @ModTypeFilter varchar(128)
	
	Declare @S varchar(4000)
	Declare @MMD varchar(512)
	
	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	Set @ParameterFileFilter = IsNull(@ParameterFileFilter, '')
	Set @AddWildcardChars = IsNull(@AddWildcardChars, 1)
	Set @ShowModSymbol = IsNull(@ShowModSymbol, 1)
	Set @ShowModName = IsNull(@ShowModName, 1)
	Set @ShowModMass = IsNull(@ShowModMass, 0)
	Set @UseModMassAlternativeName = IsNull(@UseModMassAlternativeName, 0)
	Set @message = ''
	
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
		Fragment_Ion_Tolerance real NULL DEFAULT 0,
		Enzyme varchar(64) NULL DEFAULT (''),
		Max_Missed_Cleavages int NULL DEFAULT 4,
		Parent_Mass_Type varchar(128) NULL DEFAULT ('Avg')
	)
	CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ParamFileInfo_Param_File_ID ON #TmpParamFileInfo(Param_File_ID)
	
	CREATE TABLE #TmpParamFileModInfo (
		Param_File_ID int NOT NULL ,
		Mod_Entry_ID int NOT NULL ,
		ModType varchar(64) NULL ,
		Mod_Description varchar(128) NULL,
		Used tinyint DEFAULT 0
	)
	CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ParamFileModInfo_Param_File_ID_Mod_Entry_ID ON #TmpParamFileModInfo(Param_File_ID, Mod_Entry_ID)

	CREATE TABLE #ColumnHeaders (
		UniqueRowID int Identity(1,1),
		ModType varchar(64)
	)
	CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ColumnHeaders ON #ColumnHeaders(UniqueRowID)

	CREATE TABLE #TmpParamFileModResults (
		Param_File_ID int
	)
	CREATE UNIQUE INDEX #IX_TempTable_TmpParamFileModResults_Param_File_ID ON #TmpParamFileModResults(Param_File_ID)
		
	-----------------------------------------------------------
	-- Populate a temporary table with the parameter files
	-- matching @ParameterFileFilter
	-----------------------------------------------------------

	INSERT INTO #TmpParamFileInfo (Param_File_ID)
	SELECT PF.Param_File_ID
	FROM T_Param_File_Types PFT INNER JOIN
		 T_Param_Files PF ON 
		 PFT.Param_File_Type_ID = PF.Param_File_Type_ID
	WHERE PFT.Param_File_Type = @ParameterFileTypeName AND 
		  PF.Valid = 1 AND 
		  PF.Param_File_Name LIKE @ParameterFileFilter
	--	  
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error finding matching parameter files'
		goto done
	end
	
	-----------------------------------------------------------
	-- Populate some columns in #TmpParamFileInfo
	-----------------------------------------------------------
	UPDATE #TmpParamFileInfo
	SET Fragment_Ion_Tolerance = Convert(real, PE.Entry_Value)
	FROM T_Param_Entries PE INNER JOIN
		 #TmpParamFileInfo PFI ON PE.Param_File_ID = PFI.Param_File_ID
	WHERE PE.Entry_Type = 'AdvancedParam' AND 
		  PE.Entry_Specifier = 'FragmentIonTolerance'

	UPDATE #TmpParamFileInfo
	SET Enzyme = IsNull(Enz.Enzyme_Name, PE.Entry_Value)
	FROM T_Param_Entries PE INNER JOIN
		 #TmpParamFileInfo PFI ON PE.Param_File_ID = PFI.Param_File_ID LEFT OUTER JOIN
		 T_Enzymes Enz ON Convert(int, PE.Entry_Value) = Enz.Sequest_Enzyme_Index
	WHERE PE.Entry_Type = 'BasicParam' AND 
		  PE.Entry_Specifier = 'SelectedEnzymeIndex'

	UPDATE #TmpParamFileInfo
	SET Enzyme = 'none'
	WHERE Len(Isnull(Enzyme, '')) = 0
	
	UPDATE #TmpParamFileInfo
		Set Max_Missed_Cleavages = Convert(int, PE.Entry_Value)
	FROM T_Param_Entries PE INNER JOIN
		 #TmpParamFileInfo PFI ON PE.Param_File_ID = PFI.Param_File_ID    
	WHERE PE.Entry_Type = 'BasicParam' AND 
		  PE.Entry_Specifier = 'MaximumNumberMissedCleavages'

	UPDATE #TmpParamFileInfo
	SET Parent_Mass_Type = PE.Entry_Value
	FROM T_Param_Entries PE INNER JOIN
		 #TmpParamFileInfo PFI ON PE.Param_File_ID = PFI.Param_File_ID    
	WHERE PE.Entry_Type = 'BasicParam' AND 
		  PE.Entry_Specifier = 'ParentMassType'


	Set @S = ''
	Set @S = @S + ' INSERT INTO #TmpParamFileModInfo (Param_File_ID, Mod_Entry_ID, ModType, Mod_Description)'
	Set @S = @S + ' SELECT PFMM.Param_File_ID, PFMM.Mod_Entry_ID, '
	Set @S = @S +		 ' MT.Mod_Type_Synonym + CASE WHEN R.Residue_Symbol IN (''['',''<'') THEN ''_N'''
	Set @S = @S +							   ' WHEN R.Residue_Symbol IN ('']'',''>'') THEN ''_C'''
	Set @S = @S +							   ' ELSE ''_'' + R.Residue_Symbol '
	Set @S = @S +							   ' END AS ModType,'

	If @ShowModSymbol <> 0
	Begin
		Set @S = @S + ' IsNull(Local_Symbol, ''-'') '
		
		If @ShowModName <> 0 OR @ShowModMass <> 0
			Set @S = @S + ' + '', '' + '
	End
	
	If @ShowModName <> 0
	Begin
		If @UseModMassAlternativeName = 0
			Set @S = @S + ' RTRIM(MCF.Mass_Correction_Tag)'
		Else
			Set @S = @S + ' IsNull(Alternative_Name, RTRIM(MCF.Mass_Correction_Tag))'
		
		If @ShowModMass <> 0
			 Set @S = @S + ' + '' ('' + '
	End

	If @ShowModMass <> 0
	Begin
		Set @S = @S + ' CONVERT(varchar(19), MCF.Monoisotopic_Mass_Correction)'
		If @ShowModName <> 0
			 Set @S = @S + ' + '')'''
	End
	
	Set @S = @S +     ' AS Mod_Description'
	
	Set @S = @S + ' FROM #TmpParamFileInfo PFI INNER JOIN '
	Set @S = @S +      ' T_Param_File_Mass_Mods PFMM ON PFI.Param_File_ID = PFMM.Param_File_ID INNER JOIN'
	Set @S = @S +      ' T_Mass_Correction_Factors MCF ON PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID INNER JOIN'
	Set @S = @S +      ' T_Residues R ON PFMM.Residue_ID = R.Residue_ID INNER JOIN'
	Set @S = @S +      ' T_Modification_Types MT ON PFMM.Mod_Type_Symbol = MT.Mod_Type_Symbol INNER JOIN'
	Set @S = @S +      ' T_Seq_Local_Symbols_List LSL ON PFMM.Local_Symbol_ID = LSL.Local_Symbol_ID'
    
    Exec (@S)
	--	  
	SELECT @myError = @@error, @myRowCount = @@rowcount

	
	-----------------------------------------------------------
	-- Populate #TmpParamFileModResults with the Param File IDs
	--  in #TmpParamFileInfo; this may include param files that
	--  do not have any mods
	-----------------------------------------------------------
	INSERT INTO #TmpParamFileModResults (Param_File_ID)
	SELECT Param_File_ID
	FROM #TmpParamFileInfo
	GROUP BY Param_File_ID
	--	  
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	-----------------------------------------------------------
	-- Generate a list of the unique mod types in #TmpParamFileModInfo
	-- Use these to define the column headers for the crosstab
	-----------------------------------------------------------
	INSERT INTO #ColumnHeaders (ModType)
	SELECT ModType
	FROM #TmpParamFileModInfo
	GROUP BY ModType
	ORDER BY ModType
	--	  
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount > 0
	Begin -- <a>
		-----------------------------------------------------------
		-- Use the columns in #ColumnHeaders to dynamically add 
		--  columns to #TmpParamFileModResults
		-- By using DEFAULT('') WITH VALUES, all of the rows will
		--  have blank, non-Null values for these new columns
		-----------------------------------------------------------
		Set @S = ''
		Set @S = @S + ' ALTER TABLE #TmpParamFileModResults ADD '

		SELECT @S = @S + '[' + ModType + '] varchar(128) DEFAULT ('''') WITH VALUES ' + ', '
		FROM #ColumnHeaders
		ORDER BY UniqueRowID
		--	  
		SELECT @myError = @@error, @myRowCount = @@rowcount

		-- Remove the trailing comma from @S
		Set @S = Left(@S, Len(@S)-1)
		
		-- Execute the Sql to alter the table
		Exec (@S)	
		--	  
		SELECT @myError = @@error, @myRowCount = @@rowcount


		-----------------------------------------------------------
		-- Populate #TmpParamFileModResults by looping through 
		--  the Columns in #ColumnHeaders
		-----------------------------------------------------------
		Set @ColumnHeaderRowID = 0
		Set @ContinueColumnHeader = 1
		While @ContinueColumnHeader <> 0
		Begin -- <b>
			
			SELECT TOP 1 @CurrentColumn = ModType,
						 @ColumnHeaderRowID = UniqueRowID
			FROM #ColumnHeaders
			WHERE UniqueRowID > @ColumnHeaderRowID
			ORDER BY UniqueRowID
			--	  
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount = 0
				Set @ContinueColumnHeader = 0
			Else
			Begin -- <c>

				-----------------------------------------------------------
				-- Loop through the entries for @CurrentColumn, creating a comma separated list 
				--  of the mods defined for each mod type in each parameter file
				-----------------------------------------------------------
				Set @ContinueAppendDescriptions = 1
				While @ContinueAppendDescriptions <> 0
				Begin -- <d>

					Set @ModTypeFilter = '(ModType = ''' + @CurrentColumn + ''')'

					Set @MMD = ''
					Set @MMD = @MMD + ' SELECT Param_File_ID, MIN(Mod_Description) AS Mod_Description'
					Set @MMD = @MMD + ' FROM #TmpParamFileModInfo'
					Set @MMD = @MMD + ' WHERE (Used = 0) AND ' + @ModTypeFilter
					Set @MMD = @MMD + ' GROUP BY Param_File_ID'


					Set @S = ''
					Set @S = @S + ' UPDATE #TmpParamFileModResults'
					Set @S = @S + ' SET [' + @CurrentColumn + '] = [' + @CurrentColumn + '] + '
					Set @S = @S +            ' CASE WHEN LEN([' + @CurrentColumn + ']) > 0'
					Set @S = @S +            ' THEN '', '' '
					Set @S = @S +            ' ELSE '''' '
					Set @S = @S +            ' END + SourceQ.Mod_Description'
					Set @S = @S + ' FROM #TmpParamFileModResults PFMR INNER JOIN'
					Set @S = @S +      ' (' + @MMD + ') SourceQ '
					Set @S = @S +      ' ON PFMR.Param_File_ID = SourceQ.Param_File_ID'
					--		
					Exec (@S)
					--	  
					SELECT @myError = @@error, @myRowCount = @@rowcount

					If @myRowCount = 0
						Set @ContinueAppendDescriptions = 0
					Else
					Begin -- <e>
						Set @S = ''
						Set @S = @S + ' UPDATE #TmpParamFileModInfo'
						Set @S = @S + ' SET Used = 1'
						Set @S = @S + ' FROM #TmpParamFileModInfo PFMI INNER JOIN'
						Set @S = @S +      ' (' + @MMD + ') SourceQ'
						Set @S = @S +      ' ON PFMI.Param_File_ID = SourceQ.Param_File_ID AND'
						Set @S = @S +         ' PFMI.Mod_Description = SourceQ.Mod_Description'
						Set @S = @S + ' WHERE ' + @ModTypeFilter
						--		
						Exec (@S)
						--	  
						SELECT @myError = @@error, @myRowCount = @@rowcount

					End -- </e>
				End -- </d>
			End -- </c>
		End -- </b>
	End -- </a>

	-----------------------------------------------------------
	-- Return the results
	-----------------------------------------------------------
	SELECT	PF.Param_File_Name, PF.Param_File_Description, 
			PFI.Enzyme,
			PFI.Max_Missed_Cleavages,
			PFI.Parent_Mass_Type, 			
			PFI.Fragment_Ion_Tolerance,
			PFMR.*
	FROM #TmpParamFileInfo PFI INNER JOIN 
		 T_Param_Files PF ON PFI.Param_File_ID = PF.Param_File_ID LEFT OUTER JOIN
		 #TmpParamFileModResults PFMR ON PFI.Param_File_ID = PFMR.Param_File_ID
	ORDER BY PF.Param_File_Name
		
	-----------------------------------------------------------
	-- Exit
	-----------------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[GetSequestParamFileCrosstab] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[GetSequestParamFileCrosstab] TO [DMS_User]
GO
