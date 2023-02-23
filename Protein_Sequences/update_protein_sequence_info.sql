/****** Object:  StoredProcedure [dbo].[UpdateProteinSequenceInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateProteinSequenceInfo]
/****************************************************
**
**  Desc: Adds a new protein sequence entry to T_Proteins
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**
**
**  Auth:   kja
**  Date:   10/06/2004
**
*****************************************************/
(
    @Protein_ID int,
    @sequence text,
    @length int,
    @molecular_formula varchar(128),
    @monoisotopic_mass float,
    @average_mass float,
    @sha1_hash varchar(40),
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    Declare @tmpHash as varchar(40)

    SELECT @tmpHash = SHA1_Hash
    FROM T_Proteins
    WHERE Protein_ID = @Protein_ID

    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount = 0
    begin
        SET @msg = 'Protein ID ' + @Protein_ID + ' not found'
        RAISERROR(@msg, 10, 1)
        return  -50001
    end


    ---------------------------------------------------
    -- Start transaction
    ---------------------------------------------------

    declare @transName varchar(32)
    set @transName = 'UpdateProteinCollectionEntry'
    begin transaction @transName


    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
/*      INSERT INTO T_Proteins (
            [Sequence],
            Length,
            Molecular_Formula,
            Monoisotopic_Mass,
            Average_Mass,
            SHA1_Hash,
            DateCreated,
            DateModified
        ) VALUES (
            @sequence,
            @length,
            @molecular_formula,
            @monoisotopic_mass,
            @average_mass,
            @sha1_hash,
            GETDATE(),
            GETDATE()
        )


    SELECT @Protein_ID = @@Identity
*/

    UPDATE T_Proteins
    SET [Sequence] = @sequence,
        Length = @length,
        Molecular_Formula = @molecular_formula,
        Monoisotopic_Mass = @monoisotopic_mass,
        Average_Mass = @average_mass,
        SHA1_Hash = @sha1_hash,
        DateModified = GETDATE()
    WHERE Protein_ID = @Protein_ID

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

    commit transaction @transName

    return 0

GO
GRANT EXECUTE ON [dbo].[UpdateProteinSequenceInfo] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
