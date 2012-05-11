/****** Object:  StoredProcedure [dbo].[AddNewProteinHeaders] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.AddNewProteinHeaders
/****************************************************
**
**	Desc:	Populates T_Protein_Headers with the first 50 residues of each protein in T_Proteins
**			that is not yet in T_Protein_Headers
**
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	mem
**	Date:	04/08/2008
**
*****************************************************/
(
	@ProteinIDStart int = 0,					-- If 0, then this will be updated to one more than the maximum Protein_ID value in T_Protein_Headers
	@MaxProteinsToProcess int = 0,				-- Set to a value > 0 to limit the number of proteins processed
	@InfoOnly tinyint = 0,
	@message varchar(255) = '' output 
)
AS

	Set NoCount On

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @Continue int
	Declare @ProteinIDEnd int
	Declare @ProteinsProcessed int
	Declare @BatchSize int
	
	Set @ProteinsProcessed = 0
	Set @BatchSize = 100000
	
	--------------------------------------------------------------
	-- Validate the inputs
	--------------------------------------------------------------
	
	Set @ProteinIDStart = IsNull(@ProteinIDStart, 0)
	Set @MaxProteinsToProcess = IsNull(@MaxProteinsToProcess, 0)
	Set @InfoOnly = IsNull(@InfoOnly, 0)
	Set @message = ''

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try
		
		Set @CurrentLocation = 'Initialize @ProteinIDStart'

		If IsNull(@ProteinIDStart, 0) = 0
		Begin
			-- Lookup the Maximum Protein_ID value in T_Protein_Headers
			-- We'll set @ProteinIDStart to that value plus 1
			SELECT @ProteinIDStart = Max(Protein_ID) + 1
			FROM T_Protein_Headers
			
			Set @ProteinIDStart = IsNull(@ProteinIDStart, 0)
		End

		--------------------------------------------------------------
		-- Loop through T_Proteins and populate T_Protein_Headers
		--------------------------------------------------------------
		--
		Set @CurrentLocation = 'Iterate through the proteins'
		
		Set @Continue = 1
		
		While @Continue = 1
		Begin -- <a>

			SET @ProteinIDEnd = 0
			SELECT	@ProteinIDEnd = Max(Protein_ID)
			FROM ( SELECT TOP ( @BatchSize ) Protein_ID
				FROM T_Proteins
				WHERE Protein_ID >= @ProteinIDStart
				ORDER BY Protein_ID 
				 ) LookupQ
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If IsNull(@ProteinIDEnd, -1) < 0
				Set @Continue = 0
			Else
			Begin -- <b>
				If @InfoOnly <> 0
				Begin
					Print Convert(varchar(12), @ProteinIDStart) + ' to ' + Convert(varchar(12), @ProteinIDEnd)
					Set @ProteinsProcessed = @ProteinsProcessed + @BatchSize
				End
				Else
				Begin

					INSERT INTO T_Protein_Headers (Protein_ID, Sequence_Head)
					SELECT Protein_ID, Substring("Sequence", 1, 50) AS Sequence_Head
					FROM T_Proteins
					WHERE Protein_ID >= @ProteinIDStart AND Protein_ID <= @ProteinIDEnd
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
	
					Set @ProteinsProcessed = @ProteinsProcessed + @myRowCount
					
				End
				
				Set @ProteinIDStart = @ProteinIDEnd + 1
				
				If @MaxProteinsToProcess > 0 AND @ProteinsProcessed >= @MaxProteinsToProcess
					Set @Continue = 0

			End -- </b>
		End -- </a>
		
		Set @CurrentLocation = 'Done iterating'

	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'AddNewProteinHeaders')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done
	End Catch
		
Done:
	Return @myError


GO
