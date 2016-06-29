/****** Object:  StoredProcedure [dbo].[GetProteinCollectionMemberDetail] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.GetProteinCollectionMemberDetail
/****************************************************
**
**	Desc:	Gets detailed information regarding a single protein in a protein collection
**
**			This is called from the Protein Collection Member detail report, for example:
**			http://dmsdev.pnl.gov/protein_collection_members/show/13363564
**
**	Return values: 0: success, otherwise, error code
** 
**	Auth:	mem
**	Date:	06/27/2016 mem - Initial version
**    
*****************************************************/
(
	@id int,							-- Protein reference_id; this parameter must be named id (see $calling_params->id in Q_model.php on the DMS website)
	@mode varchar(12) = 'get',			-- Ignored, but required for compatibility reasons
	@message varchar(512) = '' output,
   	@callingUser varchar(128) = ''
)
As
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''

	BEGIN TRY 

		---------------------------------------------------
		-- Validate input fields
		---------------------------------------------------
		
		Set @mode = IsNull(@mode, 'get')

		declare @proteinCollectionID int = 0
		declare @proteinName varchar(128) = ''
		declare @description varchar(900) = ''
		declare @proteinSequence varchar(max) = ''
		declare @formattedSequence varchar(max) = '<pre>'
		declare @monoisotopicMass float = 0
		declare @averageMass float = 0
		declare @residueCount int = 0
		declare @molecularFormula varchar(128) = ''
		declare @proteinId int = 0
		declare @sha1Hash varchar(40) = ''
		declare @memberId int = 0
		declare @sortingIndex int = 0

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
GRANT EXECUTE ON [dbo].[GetProteinCollectionMemberDetail] TO [DMS2_SP_User] AS [dbo]
GO
