/****** Object:  StoredProcedure [dbo].[StoreParamFileMassMods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.StoreParamFileMassMods
/****************************************************
**
**	Desc: 
**		Stores the dynamic and static mods to associate with a given parameter file
**
**		Mods must be defined in the format used for MSGF+ parameter files
**		The mod names listed in the 5th comma-separated column must be Unimod names 
**		and must match the Original_Source_Name values in  T_Mass_Correction_Factors
**
**			StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex			 # 4-plex iTraq
**			StaticMod=144.102063,  K,  fix, any,       iTRAQ4plex			 # 4-plex iTraq
**			StaticMod=C2H3N1O1,    C,  fix, any,       Carbamidomethyl       # Fixed Carbamidomethyl C (alkylation)
**
**			DynamicMod=HO3P, STY, opt, any,            Phospho               # Phosphorylation STY
**
**	Auth:	mem
**	Date:	05/16/2013 mem - Initial version
**			06/04/2013 mem - Now replacing tab characters with spaces
**			09/16/2013 mem - Now allowing mod Heme_615 to be stored (even though it is from PNNL and not UniMod)
**			09/03/2014 mem - Now treating static N-term or C-term mods that specify a target residue (instead of *) as Dynamic mods (a requirement for PHRP)
**			10/02/2014 mem - Add exception for Dyn2DZ
**			05/26/2015 mem - Add @ValidateUnimod
**			12/01/2015 mem - Now showing column Residue_Desc
**			03/14/2016 mem - Look for an entry in column Mass_Correction_Tag of T_Mass_Correction_Factors if no match is found in Original_Source_Name and @ValidateUnimod = 0
**			08/31/2016 mem - Fix logic parsing N- or C-terminal static mods that use * for the affected residue
**						   - Store static N- or C-terminal mods as type 'T' instead of 'S'
**			11/30/2016 mem - Check for a residue specification of any instead of *
**    
*****************************************************/
(
	@ParamFileID int,
	@Mods varchar(max),
	@InfoOnly tinyint = 0,
	@ReplaceExisting tinyint = 0,
	@ValidateUnimod tinyint = 1,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @MsgAddon varchar(512)
	Declare @ParamFileName varchar(255)
	
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @ReplaceExisting = IsNull(@ReplaceExisting, 0)
	Set @ValidateUnimod = IsNull(@ValidateUnimod, 1)
	
	Set @message = ''
	
	If @ParamFileID Is Null 
	Begin
		Set @message = 'The Parameter file ID must be defined; unable to continue'
		Set @myError = 53000
		Goto Done
	End

	If IsNull(@Mods, '') = ''
	Begin
		Set @message = 'The Mods to parse cannot be empty; unable to continue'
		Set @myError = 53001
		Goto Done
	End

	-----------------------------------------
	-- Make sure the parameter file ID is valid
	-----------------------------------------
	
	Set @ParamFileName = ''
	
	SELECT @ParamFileName = Param_File_Name
	FROM T_Param_Files
	WHERE Param_File_ID = @ParamFileID
	
	If IsNull(@ParamFileName, '') = ''
	Begin
		Set @message = 'Param File ID (' + Convert(varchar(12), @ParamFileID) + ') not found in T_Param_Files; unable to continue'
		Set @myError = 53002
		Goto Done
	End
	
	If @ReplaceExisting = 0 And Exists (SELECT * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @ParamFileID)
	Begin
	Set @message = 'Param File ID (' + Convert(varchar(12), @ParamFileID) + ') has existing mods in T_Param_File_Mass_Mods but @ReplaceExisting = 0; unable to continue'
		Set @myError = 53003
		Goto Done
	End

	-----------------------------------------
	-- Create some temporary tables
	-----------------------------------------
	
	CREATE TABLE #Tmp_Mods (
		EntryID int NOT NULL,
		Value varchar(2048) null
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Mods ON #Tmp_Mods (EntryID)

	
	CREATE TABLE #Tmp_ModDef (
		EntryID int NOT NULL,
		Value varchar(2048) null
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_ModDef ON #Tmp_ModDef (EntryID)

	CREATE TABLE #Tmp_Residues (
		Residue_Symbol char NOT NULL,
		Residue_ID int NULL,
		Residue_Desc varchar(64) NULL,
		Terminal_AnyAA tinyint NULL		-- Set to 1 when making any residue at a a peptide or protein N- or C-terminus; 0 if matching specific residues at terminii
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Residues ON #Tmp_Residues (Residue_Symbol)
	
	CREATE TABLE #Tmp_ModsToStore (
		Entry_ID int Identity(1,1),
		Mod_Name varchar(255),
		Mass_Correction_ID int NOT NULL,
		Mod_Type_Symbol varchar(1) NULL,
		Residue_Symbol varchar(12) NULL,
		Residue_ID int NULL,
		Local_Symbol_ID int NULL,
		Residue_Desc varchar(64) NULL
	)
	
	CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_ModsToStore ON #Tmp_ModsToStore (Entry_ID)
	
	-----------------------------------------
	-- Split @Mods on carriage returns
	-- Store the data in #Tmp_Mods
	-----------------------------------------

	Declare @Delimiter varchar(1) = ''

	If CHARINDEX(CHAR(10), @Mods) > 0
		Set @Delimiter = CHAR(10)
	Else
		Set @Delimiter = CHAR(13)
	
	INSERT INTO #Tmp_Mods (EntryID, Value)
	SELECT EntryID, Value
	FROM dbo.udfParseDelimitedListOrdered ( @mods, @Delimiter )
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	If Not Exists (SELECT * FROM #Tmp_Mods)
	Begin
		Set @message = 'Nothing returned when splitting the Mods on CR or LF'
		Set @myError = 53004
		Goto Done
	End
	

	Declare @Continue tinyint = 1
	Declare @EntryID int = 0
	Declare @EntryIDEnd int = 0

	
	Declare @CharIndex int
	Declare @ColCount int
	
	Declare @Row varchar(2048)
	Declare @Field varchar(512)
	Declare @ModType varchar(128)
	Declare @ModTypeSymbol varchar(1)
	Declare @MassCorrectionID int
	
	Declare @ModName varchar(255)
	Declare @Location varchar(128)
	
	Declare @LocalSymbolID int = 0
	Declare @LocalSymbolIDToStore int
	
	Declare @terminalMod tinyint
	Declare @residueSymbol varchar(1)
	
	SELECT @EntryIDEnd = MAX(EntryID)
	FROM #Tmp_Mods
	
	-----------------------------------------
	-- Parse the modification definitions
	-----------------------------------------
	--
	While @EntryID < @EntryIDEnd
	Begin
		SELECT TOP 1 @EntryID = EntryID, @Row = Value
		FROM #Tmp_Mods
		WHERE EntryID > @EntryID
		ORDER BY EntryID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		-- @Row show now be empty, or contain something like the following:
		-- StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex			 # 4-plex iTraq
		--   or
		-- DynamicMod=HO3P, STY, opt, any,            Phospho            # Phosphorylation STY
		
		Set @CharIndex = CharIndex('#', @Row)
		If @CharIndex > 0
			Set @Row= SubString(@Row, 1, @CharIndex-1)
		
		Set @Row = Replace (@Row, CHAR(10), '')
		Set @Row = Replace (@Row, CHAR(13), '')
		Set @Row = Replace (@Row, CHAR(9), ' ')
		Set @Row = LTrim(RTrim(IsNull(@Row, '')))
		
		If @Row <> ''
		Begin
			If @InfoOnly <> 0
				Print @Row

			TRUNCATE TABLE #Tmp_ModDef
			
			INSERT INTO #Tmp_ModDef (EntryID, Value)
			SELECT EntryID, Value
			FROM dbo.udfParseDelimitedListOrdered ( @Row, ',' )
			
			If Not Exists (SELECT * FROM #Tmp_ModDef)
			Begin
				Print 'Skipping row since #Tmp_ModDef is empty: ' + @Row
			End
			Else
			Begin
				-----------------------------------------
				-- Look for an equals sign in the first entry of #Tmp_ModDef
				-----------------------------------------
				--
				Set @Field = 1
				SELECT @Field = LTrim(RTrim(Value))
				FROM #Tmp_ModDef
				WHERE EntryID = 1
				
				-- @Field should now look something like the following:
				-- StaticMod=None
				-- DynamicMod=None
				-- DynamicMod=O1
				--
				-- Look for an equals sign in @Field
				
				Set @CharIndex = CharIndex('=', @Field)
				
				If @CharIndex <= 1
				Begin
					Print 'Skipping row since first column does not contain an equals sign: ' + @Row
				End
				Else
				Begin
					-----------------------------------------
					-- Determine the ModType
					-----------------------------------------
					--
					Set @ModType = SubString(@Field, 1, @CharIndex-1)
					If @ModType Not In ('DynamicMod', 'StaticMod')
					Begin
						Print 'Skipping row since setting is not a DynamicMod or StaticMod setting: ' + @Row
					End
					Else
					Begin
						SELECT @ColCount = COUNT(*) 
						FROM #Tmp_ModDef
				
						If @ColCount < 5
						Begin
							Print 'Skipping row since it does not have 5 comma-separated columns: ' + @Row
						End
						Else
						Begin							
							SELECT @Field = LTrim(RTrim(Value))
							FROM #Tmp_ModDef
							WHERE EntryID = 3
							
							If @ModType = 'DynamicMod'
							Begin
								Set @ModTypeSymbol = 'D'
								If @Field <> 'opt'
								Begin
									Set @message = 'DynamicMod entries must have "opt" in the 3rd column; aborting; see row: ' + @Row
									Set @myError = 53005
									Goto Done
								End
								
							End
							
							If @ModType = 'StaticMod'
							Begin
								Set @ModTypeSymbol = 'S'
								If @Field <> 'fix'
								Begin
									Set @message = 'StaticMod entries must have "fix" in the 3rd column; aborting; see row: ' + @Row
									Set @myError = 53006
									Goto Done
								End
							End
							
							-----------------------------------------
							-- Determine the Mass_Correction_ID
							-----------------------------------------						
							--
							SELECT @ModName = LTrim(RTrim(Value))
							FROM #Tmp_ModDef
							WHERE EntryID = 5
							
							-- Auto change Glu->pyro-Glu to Dehydrated
							-- Both have empirical formula H(-2) O(-1) but DMS can only associate one Unimod name with each unique empirical formula and Dehydrated is associated with H(-2) O(-1)						
							If @ModName = 'Glu->pyro-Glu'
								Set @ModName = 'Dehydrated'
								
							Set @MassCorrectionID = 0
							--
							SELECT @MassCorrectionID = Mass_Correction_ID
							FROM T_Mass_Correction_Factors
							WHERE Original_Source_Name = @ModName AND
							     (Original_Source = 'UniMod' OR @ModName IN ('Heme_615','Dyn2DZ','DeoxyHex', 'Pentose') Or @ValidateUnimod = 0)
							--
							SELECT @myRowCount = @@rowcount, @myError = @@error

							If (@myRowCount = 0 Or @MassCorrectionID = 0) And @ValidateUnimod = 0
							Begin
								SELECT @MassCorrectionID = Mass_Correction_ID
								FROM T_Mass_Correction_Factors
								WHERE Mass_Correction_Tag = @ModName
								--
								SELECT @myRowCount = @@rowcount, @myError = @@error
							End
							
							If @myRowCount = 0 Or @MassCorrectionID = 0
							Begin
								If @ValidateUnimod > 0
									Set @message = 'UniMod modification not found in T_Mass_Correction_Factors.Original_Source_Name for mod "' + @ModName + '"; see row: ' + @Row
								else
									Set @message = 'Modification name not found in T_Mass_Correction_Factors.Original_Source_Name or T_Mass_Correction_Factors.Mass_Correction_Tag for mod "' + @ModName + '"; see row: ' + @Row
									
								Set @myError = 53007
								Goto Done
							End
							
							-----------------------------------------
							-- Determine the affected residues
							-----------------------------------------
							--
							Set @Location = ''

							SELECT @Location = LTrim(RTrim(Value))
							FROM #Tmp_ModDef
							WHERE EntryID = 4
							
							If @Location Not In ('any', 'N-term', 'C-term', 'Prot-N-term', 'Prot-C-term')
							Begin
								Set @message = 'Invalid location "' + @Location + '"; should be "any", "N-term", "C-term", "Prot-N-term", or "Prot-C-term"; see row: ' + @Row
								Set @myError = 53008
								Goto Done
							End
							
							TRUNCATE TABLE #Tmp_Residues
							Set @terminalMod = 0
							
							If @Location = 'Prot-N-term'
							Begin
								Set @terminalMod = 1
								INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('[', 1)
							End
															
							If @Location = 'Prot-C-term'
							Begin
								Set @terminalMod = 1
								INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (']', 1)
							End
							
							If @Location = 'N-term'
							Begin
								Set @terminalMod = 1
								INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('<', 1)
							End
								
							If @Location = 'C-term'
							Begin
								Set @terminalMod = 1
								INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('>', 1)
							End
							
							-- Parse out the affected residue (or residues)
							-- N- or C-terminal mods use * for any residue at a terminus
							--						
							SELECT @Field = LTrim(RTrim(Value))
							FROM #Tmp_ModDef
							WHERE EntryID = 2
							
							If @Field = 'any'
							Begin
								Set @message = 'Use * to match all residues, not the word "any"; see row: ' + @Row
								Set @myError = 53010
								Goto Done
							End
							
							-- Parse each character in @Field
							Set @CharIndex = 0
							While @CharIndex < Len(@Field)
							Begin
								Set @CharIndex = @CharIndex + 1

								Set @residueSymbol = SubString(@Field, @CharIndex, 1)
								
								If @terminalMod = 1
								Begin
									If @residueSymbol <> '*'
									Begin
										-- Terminal mod that targets specific residues
										-- Store this as a dynamic terminal mod
										UPDATE #Tmp_Residues 
										SET Terminal_AnyAA = 0
										
										Set @CharIndex = Len(@Field)
									End
								End
								Else
								Begin
									-- Not matching an N or C-Terminus
									INSERT INTO #Tmp_Residues (Residue_Symbol) 
									Values (@residueSymbol)
								End
								
							End

							-----------------------------------------
							-- Determine the residue IDs for the entries in #Tmp_Residues
							-----------------------------------------
							--
							UPDATE #Tmp_Residues
							SET Residue_ID = R.Residue_ID,
							    Residue_Desc = R.Description
							FROM #Tmp_Residues
							     INNER JOIN T_Residues R
							       ON R.Residue_Symbol = #Tmp_Residues.Residue_Symbol

							-- Look for symbols that did not resolve
							IF EXISTS (SELECT * FROM #Tmp_Residues WHERE Residue_ID IS NULL)
							Begin
								Set @MsgAddon = Null
								
								SELECT @MsgAddon = @MsgAddon + Coalesce(@MsgAddon + ', ', '') + Residue_Symbol
								FROM #Tmp_Residues
								WHERE Residue_ID Is Null
								
								Set @message = 'Unrecognized residue symbol(s)s "' + @MsgAddon + '"; symbols not found in T_Residues; see row: ' + @Row
								Set @myError = 53009
								Goto Done
							End
							
							-----------------------------------------
							-- Check for N-terminal or C-terminal static mods that do not use *
							-----------------------------------------
							If @ModTypeSymbol = 'S' And Exists (Select * From #Tmp_Residues Where Residue_Symbol In ('<', '>') AND Terminal_AnyAA = 0)
							Begin
								-- Auto-switch to tracking as a dynamic mod (required for PHRP)
								Set @ModTypeSymbol = 'D'
							End
							
							-----------------------------------------
							-- Determine the Local_Symbol_ID to store for dynamic mods
							-----------------------------------------
							--
							If @ModTypeSymbol = 'D'
							Begin
								If Exists (SELECT * FROM #Tmp_ModsToStore WHERE Mod_Name = @ModName AND Mod_Type_Symbol = 'D')
								Begin
									-- This DynamicMod entry uses the same mod name as a previous one; re-use it
									SELECT TOP 1 @LocalSymbolIDToStore = Local_Symbol_ID
									FROM #Tmp_ModsToStore
									WHERE Mod_Name = @ModName AND Mod_Type_Symbol = 'D'
								End
								Else
								Begin
									-- New dynamic mod
									Set @LocalSymbolID = @LocalSymbolID + 1
									Set @LocalSymbolIDToStore = @LocalSymbolID
								End								
								
							End
							Else
							Begin
								-- Static mod; store 0
								Set @LocalSymbolIDToStore = 0
							End
							
							-----------------------------------------
							-- Append the mod defs to #Tmp_ModsToStore
							-----------------------------------------
							--
							INSERT INTO #Tmp_ModsToStore (
									Mod_Name,
									Mass_Correction_ID,
									Mod_Type_Symbol,
									Residue_Symbol,
									Residue_ID,
									Local_Symbol_ID,
									Residue_Desc
								)
							SELECT @ModName AS Mod_Name,
							       @MassCorrectionID AS MassCorrectionID,
							       CASE WHEN @ModTypeSymbol = 'S' And Residue_Symbol IN ('<', '>') Then 'T' Else @ModTypeSymbol End AS Mod_Type,
							       Residue_Symbol,
							       Residue_ID,
							       @LocalSymbolIDToStore as Local_Symbol_ID,
							       Residue_Desc
							FROM #Tmp_Residues

						End
					End
				End
			End
		End
	End
	
	
	If @InfoOnly <> 0
	Begin
		-- Preview the mod defs
		SELECT *, @ParamFileID AS Param_File_ID, @ParamFileName AS Param_File
		FROM #Tmp_ModsToStore
	End
	Else
	Begin
		-- Store the mod defs
		
		Declare @StoreMods varchar(24) = 'StoreMods'
		
		Begin Tran @StoreMods
		
		If Exists (SELECT * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @ParamFileID)
		Begin
			DELETE T_Param_File_Mass_Mods WHERE Param_File_ID = @ParamFileID
		End
		
		INSERT INTO T_Param_File_Mass_Mods (Residue_ID, Local_Symbol_ID, Mass_Correction_ID, Param_File_ID, Mod_Type_Symbol)
		SELECT Residue_ID, Local_Symbol_ID, Mass_Correction_ID, @ParamFileID, Mod_Type_Symbol
		FROM #Tmp_ModsToStore
	
		Commit Tran @StoreMods
		
		SELECT *
		FROM V_Param_File_Mass_Mods
		WHERE Param_File_ID = @ParamFileID

	End

	
Done:
	If Len(@message) > 0
		SELECT @message As Message
	
	--
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[StoreParamFileMassMods] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[StoreParamFileMassMods] TO [PNL\D3M580] AS [dbo]
GO
