/****** Object:  StoredProcedure [dbo].[GetProteinCollectionMemberDetail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetProteinCollectionMemberDetail]
/****************************************************
**
**  Desc:   Gets detailed information regarding a single protein in a protein collection
**
**          This is called from the Protein Collection Member detail report, for example:
**          http://dms2.pnl.gov/protein_collection_members/show/13363564
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/27/2016 mem - Initial version
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @id int,                            -- Protein reference_id; this parameter must be named id (see $calling_params->id in Q_model.php on the DMS website)
    @mode varchar(12) = 'get',          -- Ignored, but required for compatibility reasons
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    BEGIN TRY

        ---------------------------------------------------
        -- Validate input fields
        ---------------------------------------------------

        Set @mode = IsNull(@mode, 'get')

        Declare @proteinCollectionID int = 0
        Declare @proteinName varchar(128) = ''
        Declare @description varchar(900) = ''
        Declare @proteinSequence varchar(max) = ''
        Declare @formattedSequence varchar(max) = '<pre>'
        Declare @monoisotopicMass float = 0
        Declare @averageMass float = 0
        Declare @residueCount int = 0
        Declare @molecularFormula varchar(128) = ''
        Declare @proteinId int = 0
        Declare @sha1Hash varchar(40) = ''
        Declare @memberId int = 0
        Declare @sortingIndex int = 0

        ---------------------------------------------------
        -- Retrieve one row of data
        ---------------------------------------------------

        SELECT TOP 1
               @proteinCollectionID = Protein_Collection_ID,
               @proteinName = Protein_Name,
               @description = Description,
               @proteinSequence = Cast(Protein_Sequence as varchar(max)),
               @monoisotopicMass = Monoisotopic_Mass,
               @averageMass = Average_Mass,
               @residueCount = Residue_Count,
               @molecularFormula = Molecular_Formula,
               @proteinId = Protein_ID,
               @sha1Hash = SHA1_Hash,
               @memberId = Member_ID,
               @sortingIndex = Sorting_Index
        FROM S_V_Protein_Collection_Members
        WHERE Reference_ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        If IsNull(@proteinSequence, '') <> ''
        Begin
            ---------------------------------------------------
            -- Insert spaces and <br> tags into the protein sequence
            ---------------------------------------------------

            Declare @chunkSize int = 10
            Declare @lineLengthThreshold int = 40
            Declare @currentLineLength int = 0

            Declare @startIndex int = 1
            Declare @sequenceLength int = Len(@proteinSequence)


            While @startIndex <= @sequenceLength
            Begin
                If @currentLineLength < @lineLengthThreshold
                Begin
                    Set @formattedSequence = @formattedSequence + Substring(@proteinSequence, @startIndex, @chunkSize) + ' '
                    Set @currentLineLength = @currentLineLength + @chunkSize + 1
                End
                Else
                Begin
                    if @startIndex + @chunkSize <= @sequenceLength
                        Set @formattedSequence = @formattedSequence + Substring(@proteinSequence, @startIndex, @chunkSize) + '<br>'
                    Else
                        Set @formattedSequence = @formattedSequence + Substring(@proteinSequence, @startIndex, @chunkSize)

                    Set @currentLineLength = 0
                End

                Set @startIndex = @startIndex + @chunkSize

            End

            Set @formattedSequence = @formattedSequence + '</pre>'
        End

        ---------------------------------------------------
        -- Return the result
        ---------------------------------------------------
        --
        SELECT @proteinCollectionID AS Protein_Collection_ID,
               @proteinName AS Protein_Name,
               @description AS Description,
               @formattedSequence AS Protein_Sequence,
               @monoisotopicMass AS Monoisotopic_Mass,
               @averageMass AS Average_Mass,
               @residueCount AS Residue_Count,
               @molecularFormula AS Molecular_Formula,
               @proteinId AS Protein_ID,
               @id AS Reference_ID,
               @sha1Hash AS SHA1_Hash,
               @memberId AS Member_ID,
         @sortingIndex AS Sorting_Index


    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    END CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetProteinCollectionMemberDetail] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetProteinCollectionMemberDetail] TO [DMS2_SP_User] AS [dbo]
GO
