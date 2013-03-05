/****** Object:  StoredProcedure [dbo].[AddUpdateProteinCollectionMember] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE AddUpdateProteinCollectionMember
/****************************************************
**
**	Desc: Adds a new protein collection member
**
**	Return values: 0: success, otherwise, error code
**
**	---------------------------------------------------------------------------------
**	-- This procedure has been superseded by AddUpdateProteinCollectionMember_New
**	---------------------------------------------------------------------------------
**
**		Auth: kja
**		Date: 10/06/2004
**
**		Modified: 11/23/2005 KJA
**    
*****************************************************/
(	
	@reference_ID int,
	@protein_ID int,
	@protein_collection_ID int,
	@message varchar(256) output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)
	declare @member_ID int

	---------------------------------------------------
	-- Does entry already exist?
	---------------------------------------------------
	
--	declare @ID_Check int
--	set @ID_Check = 0
--	
--	SELECT @ID_Check = Protein_ID FROM T_Protein_Collection_Members
--	WHERE Protein_Collection_ID = @protein_collection_ID
--	
--	if @ID_Check > 0
--	begin
--		return 1  -- Entry already exists
--	end
		
	---------------------------------------------------
	-- Start transaction
	---------------------------------------------------

	declare @transName varchar(32)
	set @transName = 'AddProteinCollectionMember'
	begin transaction @transName


	---------------------------------------------------
	-- action for add mode
	---------------------------------------------------
	INSERT INTO T_Protein_Collection_Members (
		Original_Reference_ID,
		Protein_ID,
		Protein_Collection_ID
	) VALUES (
		@reference_ID,
		@protein_ID, 
		@protein_collection_ID
	)
	

--	INSERT INTO T_Protein_Collection_Members (
--		Protein_ID,
--		Protein_Collection_ID
--	) VALUES (
--		@protein_ID, 
--		@protein_collection_ID
--	)

	
	SELECT @member_ID = @@Identity 		

	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @msg = 'Insert operation failed: "' + @protein_ID + '"'
		RAISERROR (@msg, 10, 1)
		return 51007
	end
		
	commit transaction @transName
		
	return @member_ID

GO
GRANT EXECUTE ON [dbo].[AddUpdateProteinCollectionMember] TO [BUILTIN\Administrators] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateProteinCollectionMember] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
