/****** Object:  StoredProcedure [dbo].[AddArchivedFileEntryXRef] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE AddArchivedFileEntryXRef

/****************************************************
**
**	Desc: Adds an Archived File Entry to T_Archived_Output_File_Collections_XRef
**        For a given Protein Collection ID
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 03/17/2006
**    
*****************************************************/

(
	@Collection_ID int,
	@Archived_File_ID int,
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'AddArchivedFileEntryXRef'
	begin transaction @transName

	---------------------------------------------------
	-- Does entry already exist?
	---------------------------------------------------
	
	SELECT *
	FROM T_Archived_Output_File_Collections_XRef
	WHERE 
		(Archived_File_ID = @Archived_File_ID AND
		Protein_Collection_ID = @Collection_ID)
		
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
--	if @myRowCount > 0
---	begin
--		commit transaction @transname
--		return 0
--	end
	
	-------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	if @myRowCount = 0
	begin

	INSERT INTO T_Archived_Output_File_Collections_XRef (Archived_File_ID, Protein_Collection_ID)
	VALUES (@Archived_File_ID, @Collection_ID)
		
				
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
	end
		
	commit transaction @transName
	
	return 0 

GO
GRANT EXECUTE ON [dbo].[AddArchivedFileEntryXRef] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchivedFileEntryXRef] TO [pnl\d3m480] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchivedFileEntryXRef] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddArchivedFileEntryXRef] TO [svc-dms] AS [dbo]
GO
