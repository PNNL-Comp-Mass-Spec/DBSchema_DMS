/****** Object:  StoredProcedure [dbo].[AddCRC32FileAuthentication] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE AddCRC32FileAuthentication

/****************************************************
**
**	Desc: Adds a CRC32 fingerprint to a given Protein Collection Entry
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 04/15/2005
**    
*****************************************************/

(
	@Collection_ID int,
	@CRC32FileHash varchar(8),
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
	set @transName = 'AddCRC32FileAuthentication'
	begin transaction @transName


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	begin

	UPDATE T_Protein_Collections
	SET 
		Authentication_Hash = @CRC32FileHash,
		DateModified = GETDATE()
		
	WHERE (Protein_Collection_ID = @Collection_ID)	
		
				
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @msg = 'Update operation failed!'
			RAISERROR (@msg, 10, 1)
			return 51007
		end
	end
		
	commit transaction @transName
	
	return 0 

GO
GRANT EXECUTE ON [dbo].[AddCRC32FileAuthentication] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddCRC32FileAuthentication] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
