/****** Object:  StoredProcedure [dbo].[add_protein_reference] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_protein_reference]
/****************************************************
**
**  Desc: Adds a new protein reference entry to T_Protein_Names
**
**  Return values: The Reference ID for the protein name if success; otherwise, 0
**
**  Auth:   kja
**  Date:   10/08/2004 kja - Initial version
**          11/28/2005 kja - Changed for revised database architecture
**          02/11/2011 mem - Now validating that protein name is 25 characters or less; also verifying it does not contain a space
**          04/29/2011 mem - Added parameter @maxProteinNameLength; default is 25
**          12/11/2012 mem - Removed transaction
**          01/10/2013 mem - Now validating that @maxProteinNameLength is between 25 and 125; changed @maxProteinNameLength to 32
**          07/27/2022 mem - Rename arguments
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @proteinName varchar(128),      -- Protein name
    @description varchar(900),      -- Protein description
    @authorityID int,
    @proteinID int,
    @nameDescHash varchar(40),      -- SHA-1 hash of: proteinName + "_" + description + "_" + proteinId;
    @message varchar(256) output,
    @maxProteinNameLength int = 32
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    declare @msg varchar(256)
    Set @message = ''

    If IsNull(@maxProteinNameLength, 0) <= 0
        Set @maxProteinNameLength = 32

    If @maxProteinNameLength < 25
        Set @maxProteinNameLength = 25

    If @maxProteinNameLength > 125
        Set @maxProteinNameLength = 125

    ---------------------------------------------------
    -- Verify name does not contain a space and is not too long
    ---------------------------------------------------

    If @proteinName LIKE '% %'
    Begin
        set @myError = 51000
        Set @message = 'Protein name contains a space: "' + @proteinName + '"'
        RAISERROR (@message, 10, 1)
    End

    If Len(@proteinName) > @maxProteinNameLength
    Begin
        set @myError = 51001
        Set @message = 'Protein name is too long; max length is ' + Convert(varchar(12), @maxProteinNameLength) + ' characters: "' + @proteinName + '"'
        RAISERROR (@message, 10, 1)
    end

    if @myError <> 0
    Begin
        -- Return zero, since we did not add the protein
        Return 0
    End

    ---------------------------------------------------
    -- Does entry already exist?
    ---------------------------------------------------

    Declare @referenceID int = 0

    SELECT @referenceID = Reference_ID
    FROM T_Protein_Names
    WHERE Reference_Fingerprint = @nameDescHash

    if @referenceID > 0
    begin
        -- Yes, already exists
        -- Return the reference ID
        return @referenceID
    end

    INSERT INTO T_Protein_Names (
        [Name],
        Description,
        Annotation_Type_ID,
        Reference_Fingerprint,
        DateAdded, Protein_ID
    ) VALUES (
        @proteinName,
        @description,
        @authorityID,
        @nameDescHash,
        GETDATE(),
        @proteinID
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount, @referenceID = SCOPE_IDENTITY()
    --
    if @myError <> 0
    begin
        set @msg = 'Insert operation failed!'
        RAISERROR (@msg, 10, 1)
        return 51007
    end

    return @referenceID

GO
GRANT EXECUTE ON [dbo].[add_protein_reference] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
