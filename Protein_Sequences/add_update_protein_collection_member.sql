/****** Object:  StoredProcedure [dbo].[add_update_protein_collection_member] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_protein_collection_member]
/****************************************************
**
**  Desc: Adds a new protein collection member
**
**  Return values: 0: success, otherwise, error code
**
**
**
**  Auth:   kja
**  Date:   10/06/2004
**          11/23/2005 kja - Added parameters
**          12/11/2012 mem - Removed transaction
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @referenceID int,
    @proteinID int,
    @proteinCollectionID int,
    @sortingIndex int,
    @mode varchar(10),
    @message varchar(256) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @msg varchar(256)
    declare @memberID int

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

--  declare @IDCheck int
--  set @IDCheck = 0
--
--  SELECT @IDCheck = Protein_ID FROM T_Protein_Collection_Members
--  WHERE Protein_Collection_ID = @proteinCollectionID
--
--  if @IDCheck > 0
--  begin
--      return 1  -- Entry already exists
--  end

    if @mode = 'add'
    begin
        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------
        --
        INSERT INTO T_Protein_Collection_Members (
            Original_Reference_ID,
            Protein_ID,
            Protein_Collection_ID,
            Sorting_Index
        ) VALUES (
            @referenceID,
            @proteinID,
            @proteinCollectionID,
            @sortingIndex
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount, @memberID = SCOPE_IDENTITY()
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed for Protein_ID: "' + Convert(varchar(12), @proteinID) + '"'
            RAISERROR (@msg, 10, 1)
            return 51007
        end
    end

    if @mode = 'update'
    begin
        ---------------------------------------------------
        -- action for update mode
        ---------------------------------------------------
        --
        UPDATE T_Protein_Collection_Members
        SET Sorting_Index = @sortingIndex
        WHERE (Protein_ID = @proteinID and Original_Reference_ID = @referenceID and Protein_Collection_ID = @proteinCollectionID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
            --
        if @myError <> 0
        begin
            set @msg = 'Update operation failed for Protein_ID: "' + Convert(varchar(12), @proteinID) + '"'
            RAISERROR (@msg, 10, 1)
            return 51008
        end
    end

    return @memberID

GO
GRANT EXECUTE ON [dbo].[add_update_protein_collection_member] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
