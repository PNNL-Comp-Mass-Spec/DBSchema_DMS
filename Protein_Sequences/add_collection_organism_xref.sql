/****** Object:  StoredProcedure [dbo].[add_collection_organism_xref] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_collection_organism_xref]
/****************************************************
**
**  Desc: Adds an entry to T_Collection_Organism_Xref
**
**  Returns the ID value for the mapping in T_Collection_Organism_Xref
**  Returns 0 or a negative number if unable to update T_Collection_Organism_Xref
**
**  Auth:   kja
**  Date:   06/01/2006
**          08/15/2006 mem - Updated to return @memberID if the mapping already exists, or 0 or a negative number if it doesn't
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @proteinCollectionID int,
    @organismID int,
    @message varchar(256) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)
    declare @memberID int

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    --execute @authId = get_naming_authority_id @name

    SELECT @memberID = ID FROM T_Collection_Organism_Xref
    WHERE (Protein_Collection_ID = @ProteinCollectionID AND
           Organism_ID = @OrganismID)

    if @memberID > 0
    begin
        return @memberID
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'add_naming_authority'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO T_Collection_Organism_Xref
               (Protein_Collection_ID, Organism_ID)
    VALUES     (@ProteinCollectionID, @OrganismID)


    SELECT @memberID = @@Identity

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Insert operation failed for Protein Collection: "' + @ProteinCollectionID + '"'
        RAISERROR (@msg, 10, 1)
        return -51007
    end

    commit transaction @transName

    return @memberID

GO
GRANT EXECUTE ON [dbo].[add_collection_organism_xref] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
