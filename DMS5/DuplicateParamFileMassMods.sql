/****** Object:  StoredProcedure [dbo].[DuplicateParamFileMassMods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.DuplicateParamFileMassMods
/****************************************************
**
**	Desc: 
**		Copies the mass modification definitions from
**		an existing parameter file to a new parameter file
**
**		Requires that the new parameter file exists in
**		T_Param_Files, but does not yet have any entries 
**		in T_Param_File_Mass_Mods
**
**		If @UpdateParamEntries = 1, then will also populate T_Param_Entries
**
**	Auth:	mem
**	Date:	05/04/2009
**			07/01/2009 mem - Added parameter @DestParamFileID
**			07/22/2009 mem - Now returning the suggested query for tweaking the newly entered mass mods
**    
*****************************************************/
(
	@SourceParamFileID int,
	@DestParamFileID int,
	@UpdateParamEntries tinyint = 1,		-- Whe non-zero, then updates T_Param_Entries in addition to T_Param_File_Mass_Mods
	@InfoOnly tinyint = 0,
	@message varchar(512)='' OUTPUT
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @S varchar(2048)
						 
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @UpdateParamEntries = IsNull(@UpdateParamEntries, 1)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @message = ''
	
	If @SourceParamFileID Is Null Or @DestParamFileID Is Null
	Begin
		Set @message = 'Both the source and target parameter file ID must be defined; unable to continue'
		Set @myError = 53000
		Goto Done
	End


	Set @S = ''
	Set @S = @S + ' SELECT PFMM.*, R.Residue_Symbol,'
	Set @S = @S +        ' MCF.Mass_Correction_Tag, MCF.Monoisotopic_Mass_Correction,'
	Set @S = @S +        ' SLS.Local_Symbol, R.Description AS Residue_Desc'
	Set @S = @S + ' FROM dbo.T_Param_File_Mass_Mods PFMM'
	Set @S = @S +      ' INNER JOIN dbo.T_Residues R'
	Set @S = @S +        ' ON PFMM.Residue_ID = R.Residue_ID'
	Set @S = @S +      ' INNER JOIN dbo.T_Mass_Correction_Factors MCF'
	Set @S = @S +        ' ON PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID'
	Set @S = @S +      ' INNER JOIN dbo.T_Seq_Local_Symbols_List SLS'
	Set @S = @S +        ' ON PFMM.Local_Symbol_ID = SLS.Local_Symbol_ID'
	Set @S = @S +      ' WHERE (PFMM.Param_File_ID = ' + Convert(varchar(12), @DestParamFileID) + ')'
	Set @S = @S + ' ORDER BY PFMM.Param_File_ID, PFMM.Local_Symbol_ID, R.Residue_Symbol'
	
	Print @S

	-----------------------------------------
	-- Make sure the parameter file IDs are valid
	-----------------------------------------
	
	If Not Exists (SELECT * FROM T_Param_Files WHERE Param_File_ID = @SourceParamFileID)
	Begin
		Set @message = 'Source Param File ID (' + Convert(varchar(12), @SourceParamFileID) + ') not found in T_Param_Files; unable to continue'
		Set @myError = 53001
		Goto Done
	End

	If Not Exists (SELECT * FROM T_Param_Files WHERE Param_File_ID = @DestParamFileID)
	Begin
		Set @message = 'Destination Param File ID (' + Convert(varchar(12), @DestParamFileID) + ') not found in T_Param_Files; unable to continue'
		Set @myError = 53002
		Goto Done
	End

	-----------------------------------------
	-- Make sure the destination parameter file does not yet have any mass mods defined	
	-----------------------------------------

	If Exists (SELECT * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @DestParamFileID)
	Begin
		Set @message = 'Destination Param File ID (' + Convert(varchar(12), @DestParamFileID) + ') already has entries in T_Param_File_Mass_Mods; unable to continue'
		Set @myError = 53003
		Goto Done
	End

	If @UpdateParamEntries <> 0
	Begin
		If Exists (SELECT * FROM T_Param_Entries WHERE Param_File_ID = @DestParamFileID)
		Begin
			Set @message = 'Destination Param File ID (' + Convert(varchar(12), @DestParamFileID) + ') already has entries in T_Param_Entries; unable to continue'
			Set @myError = 53004
			Goto Done
		End
	End

	If @InfoOnly <> 0
	Begin
		SELECT PFMM.*, R.Residue_Symbol, MCF.Mass_Correction_Tag, 
			MCF.Monoisotopic_Mass_Correction, SLS.Local_Symbol, 
			R.Description AS Residue_Desc,
			@DestParamFileID AS Destination_Param_File_ID
		FROM dbo.T_Param_File_Mass_Mods PFMM INNER JOIN
			dbo.T_Residues R ON 
			PFMM.Residue_ID = R.Residue_ID INNER JOIN
			dbo.T_Mass_Correction_Factors MCF ON 
			PFMM.Mass_Correction_ID = MCF.Mass_Correction_ID INNER JOIN
			dbo.T_Seq_Local_Symbols_List SLS ON 
			PFMM.Local_Symbol_ID = SLS.Local_Symbol_ID
		WHERE (PFMM.Param_File_ID = @SourceParamFileID)
		ORDER BY PFMM.Param_File_ID, PFMM.Local_Symbol_ID, R.Residue_Symbol
		
		If @UpdateParamEntries <> 0
		Begin
			SELECT PE.*, @DestParamFileID AS Destination_Param_File_ID
			FROM dbo.T_Param_Entries PE
			WHERE (Param_File_ID = @SourceParamFileID)
			ORDER BY PE.Entry_Sequence_Order
		End
	End
	Else
	Begin
		-- Copy the mass mod definitions
		INSERT INTO T_Param_File_Mass_Mods( Param_File_ID,
											Residue_ID,
											Local_Symbol_ID,
											Mod_Type_Symbol,
											Mass_Correction_ID )
		SELECT @DestParamFileID AS Param_File_ID,
			Residue_ID,
			Local_Symbol_ID,
			Mod_Type_Symbol,
			Mass_Correction_ID
		FROM T_Param_File_Mass_Mods PFMM
		WHERE (Param_File_ID = @SourceParamFileID)
		ORDER BY Param_File_ID, Mod_Type_Symbol, Local_Symbol_ID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		If @myError <> 0
		Begin
			Set @message = 'Error copying mass mods from Param File ID ' + Convert(varchar(12), @SourceParamFileID) + ' to Param File ID ' + Convert(varchar(12), @DestParamFileID) + '; error code = ' + Convert(varchar(12), @myError)
			Goto Done
		End

		If @myRowCount = 0
			Set @message = 'Warning: Param File ID ' + Convert(varchar(12), @SourceParamFileID) + ' does not have any entries in T_Param_File_Mass_Mods'

		If @UpdateParamEntries <> 0
		Begin
			INSERT INTO T_Param_Entries( Entry_Sequence_Order,
			                             Entry_Type,
			                             Entry_Specifier,
			                             Entry_Value,
			                             Param_File_ID )
			SELECT Entry_Sequence_Order,
			       Entry_Type,
			       Entry_Specifier,
			       Entry_Value,
			       @DestParamFileID AS Param_File_ID
			FROM T_Param_Entries
			WHERE (Param_File_ID = @SourceParamFileID)
			ORDER BY Entry_Sequence_Order
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
			
		End

		SELECT *
		FROM V_Param_File_Mass_Mods
		WHERE Param_File_ID = @DestParamFileID


	End
	
Done:
	If Len(@message) > 0
		SELECT @message As Message
	
	--
	Return @myError

GO
GRANT EXECUTE ON [dbo].[DuplicateParamFileMassMods] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateParamFileMassMods] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DuplicateParamFileMassMods] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateParamFileMassMods] TO [PNL\D3M578] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DuplicateParamFileMassMods] TO [PNL\D3M580] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateParamFileMassMods] TO [PNL\D3M580] AS [dbo]
GO
