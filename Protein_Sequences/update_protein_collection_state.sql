/****** Object:  StoredProcedure [dbo].[update_protein_collection_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_protein_collection_state]
/****************************************************
**
**  Desc: Adds a new protein collection member
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   07/28/2005
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @proteinCollectionID int,
    @stateID int,
    @message varchar(256) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Make sure that the @stateID value exists in
    -- T_Protein_Collection_States
    ---------------------------------------------------

    declare @IDCheck int
    set @IDCheck = 0

    SELECT @IDCheck = Collection_State_ID FROM T_Protein_Collection_States
    WHERE Collection_State_ID = @stateID

    if @IDCheck = 0
    begin
        set @message = 'Collection_State_ID: "' + @stateID + '" does not exist'
        RAISERROR (@message, 10, 1)
        return 1  -- State Does not exist
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'update_protein_collection_state'
    begin transaction @transName

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
        UPDATE T_Protein_Collections
        SET
            Collection_State_ID = @stateID,
            DateModified = GETDATE()
        WHERE
            (Protein_Collection_ID = @proteinCollectionID)
    --

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Update operation failed: The state of "' + @proteinCollectionID + '" could not be updated'
        RAISERROR (@message, 10, 1)
        return 51007
    end


    commit transaction @transName

    return 0

GO
GRANT EXECUTE ON [dbo].[update_protein_collection_state] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
