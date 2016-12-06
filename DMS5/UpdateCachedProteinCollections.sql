/****** Object:  StoredProcedure [dbo].[UpdateCachedProteinCollections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE UpdateCachedProteinCollections
/****************************************************
**
**	Desc:	Updates the data in T_Cached_Protein_Collections
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	06/13/2016 mem - Initial Version
**
*****************************************************/
(
	@message varchar(255) = '' output
)
AS

	Set XACT_ABORT, nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	set @message = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'
	
	Begin Try
		Set @CurrentLocation = 'Update T_Cached_Protein_Collections'
		--
		 
		MERGE [dbo].[T_Cached_Protein_Collections] AS t
		USING (SELECT  ID, Organism_ID, [Name], Description, 
		       Entries, Residues, [Type], Filesize
		       FROM dbo.S_V_Protein_Collection_Picker) as s
		ON ( t.[ID] = s.[ID] AND t.[Organism_ID] = s.[Organism_ID])
		WHEN MATCHED AND (
			t.[Name] <> s.[Name] OR
			ISNULL( NULLIF(t.[Description], s.[Description]),
					NULLIF(s.[Description], t.[Description])) IS NOT NULL OR
			ISNULL( NULLIF(t.[Entries], s.[Entries]),
					NULLIF(s.[Entries], t.[Entries])) IS NOT NULL OR
			ISNULL( NULLIF(t.[Residues], s.[Residues]),
					NULLIF(s.[Residues], t.[Residues])) IS NOT NULL OR
			ISNULL( NULLIF(t.[Type], s.[Type]),
					NULLIF(s.[Type], t.[Type])) IS NOT NULL OR
			ISNULL( NULLIF(t.[Filesize], s.[Filesize]),
					NULLIF(s.[Filesize], t.[Filesize])) IS NOT NULL
			)
		THEN UPDATE SET 
			[Name] = s.[Name],
			[Description] = s.[Description],
			[Entries] = s.[Entries],
			[Residues] = s.[Residues],
			[Type] = s.[Type],
			[Filesize] = s.[Filesize],
			[Last_Affected] = GetDate()
		WHEN NOT MATCHED BY TARGET THEN
			INSERT([ID], [Organism_ID], [Name], [Description], [Entries], [Residues], [Type], [Filesize], [Created], [Last_Affected])
			VALUES(s.[ID], s.[Organism_ID], s.[Name], s.[Description], s.[Entries], s.[Residues], s.[Type], s.[Filesize], GetDate(), GetDate())
		WHEN NOT MATCHED BY SOURCE THEN DELETE
		;
	
		if @myError <> 0
		begin
			set @message = 'Error updating T_Cached_Protein_Collections via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
			execute PostLogEntry 'Error', @message, 'UpdateCachedProteinCollections'
			goto Done
		end

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateCachedProteinCollections')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done		
	End Catch
			
Done:
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedProteinCollections] TO [DDL_Viewer] AS [dbo]
GO
