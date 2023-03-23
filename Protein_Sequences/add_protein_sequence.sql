/****** Object:  StoredProcedure [dbo].[add_protein_sequence] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_protein_sequence]
/****************************************************
**
**  Desc: Adds a new protein sequence entry to T_Proteins
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   10/06/2004
**          12/11/2012 mem - Removed transaction
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/23/2023 mem - Remove underscores from variables
**
*****************************************************/
(
    @sequence text,
    @length int,
    @molecularFormula varchar(128),
    @monoisotopicMass float,
    @averageMass float,
    @sha1Hash varchar(40),
    @isEncrypted tinyint,
    @mode varchar(12) = 'add',      -- The only option is "add"
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    declare @ProteinID int
    set @ProteinID = 0

    execute @ProteinID = get_protein_id @length, @sha1Hash

    if @ProteinID > 0 and @mode = 'add'
    begin
        Return @ProteinID
    end


    if @mode = 'add'
    begin
        ---------------------------------------------------
        -- action for add mode
        ---------------------------------------------------
        --
        INSERT INTO T_Proteins (
            [Sequence],
            Length,
            Molecular_Formula,
            Monoisotopic_Mass,
            Average_Mass,
            SHA1_Hash,
            IsEncrypted,
            DateCreated,
            DateModified
        ) VALUES (
            @sequence,
            @length,
            @molecularFormula,
            @monoisotopicMass,
            @averageMass,
            @sha1Hash,
            @isEncrypted,
            GETDATE(),
            GETDATE()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount, @ProteinID = SCOPE_IDENTITY()
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed!'
            RAISERROR (@msg, 10, 1)
            Return 51007
        end
    end

    Return @ProteinID

GO
GRANT EXECUTE ON [dbo].[add_protein_sequence] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
