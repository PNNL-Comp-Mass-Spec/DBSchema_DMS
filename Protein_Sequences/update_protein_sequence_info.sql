/****** Object:  StoredProcedure [dbo].[update_protein_sequence_info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_protein_sequence_info]
/****************************************************
**
**  Desc: Adds a new protein sequence entry to T_Proteins
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   10/06/2004
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @proteinID int,
    @sequence text,
    @length int,
    @molecularFormula varchar(128),
    @monoisotopicMass float,
    @averageMass float,
    @sha1Hash varchar(40),
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
    WHERE Protein_ID = @ProteinID

    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount = 0
    begin
        SET @msg = 'Protein ID ' + @ProteinID + ' not found'
        RAISERROR(@msg, 10, 1)
        Return  -50001
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
            @molecularFormula,
            @monoisotopicMass,
            @averageMass,
            @sha1Hash,
            GETDATE(),
            GETDATE()
        )


    SELECT @ProteinID = @@Identity
*/

    UPDATE T_Proteins
    SET [Sequence] = @sequence,
        Length = @length,
        Molecular_Formula = @molecularFormula,
        Monoisotopic_Mass = @monoisotopicMass,
        Average_Mass = @averageMass,
        SHA1_Hash = @sha1Hash,
        DateModified = GETDATE()
    WHERE Protein_ID = @ProteinID

        --
    SELECT @myError = @@error, @myRowCount = @@rowcount
        --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @msg = 'Update operation failed!'
        RAISERROR (@msg, 10, 1)
        Return 51007
    end

    commit transaction @transName

    Return 0

GO
GRANT EXECUTE ON [dbo].[update_protein_sequence_info] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
