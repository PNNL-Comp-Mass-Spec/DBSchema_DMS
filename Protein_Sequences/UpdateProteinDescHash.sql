/****** Object:  StoredProcedure [dbo].[UpdateProteinDescHash] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE UpdateProteinDescHash

/****************************************************
**
**	Desc: Updates the SHA1 fingerprint for a given Protein Description Entry
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 02/21/2007
**    
*****************************************************/

(
	@Description_ID int,
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
	set @transName = 'UpdateProteinDescHash'
	begin transaction @transName


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	begin

	UPDATE T_Protein_Descriptions
	SET 
		Fingerprint = @SHA1Hash		
	WHERE (Description_ID = @Description_ID)	
		
				
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
