/****** Object:  StoredProcedure [dbo].[AddProteinReference] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddProteinReference]

/****************************************************
**
**	Desc: Adds a new protein reference entry to T_Protein_Names
**
**	Return values: The Reference ID for the protein name if success; otherwise, 0
**
**	Parameters: 
**
**	
**
**	Auth:	kja
**	Date:	10/08/2004 kja - Initial version
**			11/28/2005 kja - Changed for revised database architecture
**			02/11/2011 mem - Now validating that protein name is 25 characters or less; also verifying it does not contain a space
**			04/29/2011 mem - Added parameter @MaxProteinNameLength; default is 25
**
*****************************************************/

(
	@name varchar(128),
	@description varchar(900),
	@authority_ID int,
	@protein_ID int,
	@nameDescHash varchar(40),
	@message varchar(256) output,
	@MaxProteinNameLength int = 34
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	declare @msg varchar(256)
	Set @message = ''

	---------------------------------------------------
	-- Verify name does not contain a space and is not too long
	---------------------------------------------------
	
	If @name LIKE '% %'
	Begin
		set @myError = 51000
		Set @message = 'Protein name contains a space: "' + @name + '"'
		RAISERROR (@message, 10, 1)
	End
	
	If Len(@name) > @MaxProteinNameLength
	Begin
		set @myError = 51001
		Set @message = 'Protein name is too long; max length is ' + Convert(varchar(12), @MaxProteinNameLength) + ' characters: "' + @name + '"'
		RAISERROR (@message, 10, 1)
	end
	
	if @myError <> 0
	Begin
		-- Return zero, since we did not add the protein
		Return 0
	End

	---------------------------------------------------
	-- Does entry already exist?
	---------------------------------------------------
	
	declare @Reference_ID int
	set @Reference_ID = 0
	
	execute @Reference_ID = GetProteinReferenceID @name, @nameDescHash
	
	if @Reference_ID > 0
	begin
		-- Yes, already exists
		-- Return the reference ID
		return @Reference_ID
	end
	

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'AddProteinReferenceEntry'
	begin transaction @transName

--	INSERT INTO T_Protein_Names (
--		[Name],
--		Description,
--		Organism_ID,
--		Annotation_Type_ID,
--		Reference_Fingerprint,
--		DateAdded, Protein_ID
--	) VALUES (
--		@name, 
--		@description,
--		@organism_ID, 
--		@authority_ID,
--		@nameDescHash,
--		GETDATE(),
--		@protein_ID
--	)
	
		INSERT INTO T_Protein_Names (
			[Name],
			Description,
			Annotation_Type_ID,
			Reference_Fingerprint,
			DateAdded, Protein_ID
		) VALUES (
			@name, 
			@description,
			@authority_ID,
			@nameDescHash,
			GETDATE(),
			@protein_ID
		)

		
		
	--execute @Protein_ID = GetProteinID @length, @sha1_hash 		
	SELECT @Reference_ID = @@Identity
		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @msg = 'Insert operation failed!'
		RAISERROR (@msg, 10, 1)
		return 51007
	end
		
	commit transaction @transName

	return @Reference_ID

GO
GRANT EXECUTE ON [dbo].[AddProteinReference] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddProteinReference] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
