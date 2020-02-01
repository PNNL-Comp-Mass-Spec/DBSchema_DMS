/****** Object:  StoredProcedure [dbo].[AddUpdateOrganismDBFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateOrganismDBFile]
/****************************************************
**
**  Desc: Adds new or edits existing Legacy Organism DB File in T_Organism_DB_File
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	mem
**  Date:	01/24/2014 mem - Initial version
**			01/15/2015 mem - Added parameter @FileSizeKB
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**          01/31/2020 mem - Add @returnCode, which duplicates the integer returned by this procedure; @returnCode is varchar for compatibility with Postgres error codes
**    
*****************************************************/
(
	@FastaFileName varchar(128),
	@OrganismName varchar(128),
	@NumProteins int,
	@NumResidues bigint,
	@FileSizeKB int=0,
	@message varchar(512) = '' output,
    @returnCode varchar(64) = '' output
)
As
	set nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0

	Set @message = ''    
    Set @returnCode = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateOrganismDBFile', @raiseError = 1
	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	If IsNull(@FastaFileName, '') = ''
	begin
		Set @message = '@FastaFileName cannot be blank'
		Set @myError = 62000
		Goto Done
	End

	If IsNull(@OrganismName, '') = ''
	begin
		Set @message = '@OrganismName cannot be blank'
		Set @myError = 62001
		Goto Done
	End

	Set @NumProteins = IsNull(@NumProteins, 0)
	Set @NumResidues = IsNull(@NumResidues, 0)
	Set @FileSizeKB = IsNull(@FileSizeKB, 0)
	
	---------------------------------------------------
	-- Resolve @OrganismName to @OrganismID
	---------------------------------------------------

	Declare @OrganismID int = 0
	
	SELECT @OrganismID = Organism_ID
	FROM T_Organisms
	WHERE OG_name = @OrganismName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount

	If @myRowCount = 0 Or IsNull(@OrganismID, 0) <= 0
	Begin
		Set @message = 'Could not find organism in T_Organisms: ' + @OrganismName
		Set @myError = 62001
		Goto Done
	End

	---------------------------------------------------
	-- Add/Update T_Organism_DB_File
	---------------------------------------------------
	--
	Declare @ExistingEntry tinyint = 0
	
	If Exists (SELECT * FROM T_Organism_DB_File WHERE FileName = @FastaFileName)
		Set @ExistingEntry = 1
	
	MERGE T_Organism_DB_File AS target
	USING ( SELECT @FastaFileName AS FileName,
				@OrganismID AS Organism_ID,
				'Auto-created' AS Description,
				0 AS Active,
				@NumProteins AS NumProteins,
				@NumResidues AS NumResidues,
				@FileSizeKB AS FileSizeKB,
				1 AS Valid
		) AS Source (FileName, Organism_ID, Description, Active, NumProteins, NumResidues, FileSizeKB, Valid)
		ON (target.Filename = source.Filename)
	WHEN Matched THEN 
		UPDATE Set 
			Organism_ID = source.Organism_ID,
			Description = source.Description + '; updated ' + CONVERT(varchar(24), GETDATE(), 120),
			Active = source.Active,
			NumProteins = source.NumProteins,
			NumResidues = source.NumResidues,
			File_Size_KB = source.FileSizeKB,
			Valid = source.Valid
	WHEN Not Matched THEN
		INSERT (FileName, Organism_ID, Description, Active, NumProteins, NumResidues, File_Size_KB, Valid)
		VALUES (source.FileName, source.Organism_ID, source.Description, source.Active, source.NumProteins, source.NumResidues, source.FileSizeKB, source.Valid)
	;
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @ExistingEntry = 1
		Set @Message = 'Updated ' + @FastaFileName + ' in T_Organism_DB_File'
	Else
		Set @Message = 'Added ' + @FastaFileName + ' to T_Organism_DB_File'

Done:
    Set @returnCode = Cast(@myError As varchar(64))
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateOrganismDBFile] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganismDBFile] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganismDBFile] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateOrganismDBFile] TO [svc-dms] AS [dbo]
GO
