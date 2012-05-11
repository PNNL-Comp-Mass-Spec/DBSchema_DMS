/****** Object:  StoredProcedure [dbo].[UpdateProteinNameHash] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE UpdateProteinNameHash

/****************************************************
**
**	Desc: Updates t SHA1 fingerprint for a given Protein Reference Entry
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 03/13/2006
**    
*****************************************************/

(
	@Reference_ID int,
	@SHA1Hash varchar(40),
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
	set @transName = 'UpdateProteinNameHash'
	begin transaction @transName


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	begin

	UPDATE T_Protein_Names
	SET 
		Reference_Fingerprint = @SHA1Hash		
	WHERE (Reference_ID = @Reference_ID)	
		
				
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
GRANT EXECUTE ON [dbo].[UpdateProteinNameHash] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateProteinNameHash] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
