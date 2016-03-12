/****** Object:  StoredProcedure [dbo].[UpdateProteinCollectionState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE UpdateProteinCollectionState
/****************************************************
**
**	Desc: Adds a new protein collection member
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: kja
**		Date: 07/28/2005
**    
*****************************************************/
(	
	@protein_collection_ID int,
	@state_ID int,
	@message varchar(256) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)
	
	---------------------------------------------------
	-- Make sure that the @state_ID value exists in
	-- T_Protein_Collection_States
	---------------------------------------------------

	declare @ID_Check int
	set @ID_Check = 0
	
	SELECT @ID_Check = Collection_State_ID FROM T_Protein_Collection_States
	WHERE Collection_State_ID = @state_ID
	
	if @ID_Check = 0
	begin
		set @message = 'Collection_State_ID: "' + @state_ID + '" does not exist'
		RAISERROR (@message, 10, 1)
		return 1  -- State Does not exist
	end

	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'UpdateProteinCollectionState'
	begin transaction @transName
	
	---------------------------------------------------
	-- action for update mode
	---------------------------------------------------
		UPDATE T_Protein_Collections
		SET
			Collection_State_ID = @state_ID, 
			DateModified = GETDATE()
		WHERE
			(Protein_Collection_ID = @protein_collection_ID)
	--
	
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Update operation failed: The state of "' + @protein_collection_ID + '" could not be updated'
		RAISERROR (@message, 10, 1)
		return 51007
	end
	
	
	commit transaction @transName
		
	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateProteinCollectionState] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
