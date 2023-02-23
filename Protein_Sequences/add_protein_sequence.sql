/****** Object:  StoredProcedure [dbo].[AddProteinSequence] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddProteinSequence]
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
**          12/11/2012 mem - Removed transaction
**
*****************************************************/
(
    @sequence text,
    @length int,
    @molecular_formula varchar(128),
    @monoisotopic_mass float,
    @average_mass float,
    @sha1_hash varchar(40),
    @is_encrypted tinyint,
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

    declare @Protein_ID int
    set @Protein_ID = 0

    execute @Protein_ID = GetProteinID @length, @sha1_hash

    if @Protein_ID > 0 and @mode = 'add'
    begin
        return @Protein_ID
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
            @molecular_formula,
            @monoisotopic_mass,
            @average_mass,
            @sha1_hash,
            @is_encrypted,
            GETDATE(),
            GETDATE()
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount, @Protein_ID = SCOPE_IDENTITY()
        --
        if @myError <> 0
        begin
            set @msg = 'Insert operation failed!'
            RAISERROR (@msg, 10, 1)
            return 51007
        end
    end

    return @Protein_ID

GO
GRANT EXECUTE ON [dbo].[AddProteinSequence] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
