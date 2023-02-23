/****** Object:  StoredProcedure [dbo].[AddCollectionOrganismXRef] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddCollectionOrganismXRef]
/****************************************************
**
**  Desc: Adds an entry to T_Collection_Organism_Xref
**
**  Returns the ID value for the mapping in T_Collection_Organism_Xref
**  Returns 0 or a negative number if unable to update T_Collection_Organism_Xref
**
**  Parameters:
**
**  Auth:   kja
**  Date:   06/01/2006
**          08/15/2006 mem - Updated to return @member_ID if the mapping already exists, or 0 or a negative number if it doesn't
**
*****************************************************/
(
    @Protein_Collection_ID int,
    @Organism_ID int,
    @message varchar(256) output
)
AS
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

    --execute @auth_id = GetNamingAuthorityID @name

    SELECT @member_ID = ID FROM T_Collection_Organism_Xref
    WHERE (Protein_Collection_ID = @Protein_Collection_ID AND
           Organism_ID = @Organism_ID)

    if @member_ID > 0
    begin
        return @member_ID
    end

    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'AddNamingAuthority'
    begin transaction @transName


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    INSERT INTO T_Collection_Organism_Xref
               (Protein_Collection_ID, Organism_ID)
    VALUES     (@Protein_Collection_ID, @Organism_ID)


    SELECT @member_ID = @@Identity

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Insert operation failed for Protein Collection: "' + @Protein_Collection_ID + '"'
        RAISERROR (@msg, 10, 1)
        return -51007
    end

    commit transaction @transName

    return @member_ID

GO
GRANT EXECUTE ON [dbo].[AddCollectionOrganismXRef] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
