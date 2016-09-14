/****** Object:  StoredProcedure [dbo].[PromoteProteinCollectionState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.PromoteProteinCollectionState
/****************************************************
**
**	Desc:	Examines protein collections with a state of 1
**			Looks in MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
**			for any analysis jobs that refer to the given
**			protein collection.  If any are found, the state
**			for the given protein collection is changed to 3
**
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	mem
**	Date:	09/13/2007
**			04/08/2008 mem - Added parameter @AddNewProteinHeaders
**			02/23/2016 mem - Add set XACT_ABORT on
**			09/12/2016 mem - Add parameter @mostRecentMonths
**
*****************************************************/
(
	@AddNewProteinHeaders tinyint = 1,
	@mostRecentMonths int = 12,			-- Used to filter protein collections that we will examine
	@InfoOnly tinyint = 0,
	@message varchar(255) = '' output 
)
AS

	Set XACT_ABORT, nocount on

	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	Declare @Continue int
	Declare @ProteinCollectionID int
	Declare @ProteinCollectionName varchar(128)

	Declare @NameFilter varchar(256)
	Declare @JobCount int
	
	Declare @ProteinCollectionsUpdated varchar(max)
	Declare @ProteinCollectionCountUpdated int
	
	Set @ProteinCollectionCountUpdated = 0
	Set @ProteinCollectionsUpdated = ''
	
	Set @message = ''

	--------------------------------------------------------------
	-- Validate the inputs
	--------------------------------------------------------------
	
	Set @AddNewProteinHeaders = IsNull(@AddNewProteinHeaders, 1)

	Set @mostRecentMonths = IsNull(@mostRecentMonths, 12)
	If @mostRecentMonths <= 0
		Set @mostRecentMonths = 12

	If @mostRecentMonths > 2000
		Set @mostRecentMonths = 2000

	Set @InfoOnly = IsNull(@InfoOnly, 0)

	--------------------------------------------------------------
	-- Loop through the protein collections with a state of 1
	-- Limit to protein collections created within the last @mostRecentMonths months
	--------------------------------------------------------------
	--
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try
		
		Set @ProteinCollectionID = 0
		Set @Continue = 1
		
		While @Continue = 1
		Begin
			Set @CurrentLocation = 'Find the next Protein collection with state 1'
			
			SELECT TOP 1 @ProteinCollectionID = Protein_Collection_ID, 
						 @ProteinCollectionName = FileName
			FROM T_Protein_Collections
			WHERE Collection_State_ID = 1 AND
			      Protein_Collection_ID > @ProteinCollectionID AND
			      DateCreated >= DATEADD(month, -@mostRecentMonths, GETDATE())
			ORDER BY Protein_Collection_ID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			If @myRowCount <> 1
				Set @Continue = 0
			Else
			Begin
				Set @CurrentLocation = 'Look for jobs in V_DMS_Analysis_Job_Info that used ' + @ProteinCollectionName

				If @infoOnly > 0
					Print @CurrentLocation

				Set @NameFilter = '%' + @ProteinCollectionName + '%'
				
				Set @JobCount = 0
				SELECT @JobCount = COUNT(*)
				FROM MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
				WHERE (ProteinCollectionList LIKE @NameFilter)
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @JobCount > 0
				Begin
					Set @message = 'Updated state for Protein Collection "' + @ProteinCollectionName + '" from 1 to 3 since ' + Convert(varchar(12), @JobCount) + ' jobs are defined in DMS with this protein collection'

					If @InfoOnly = 0
					Begin
						Set @CurrentLocation = 'Update state for CollectionID ' + Convert(varchar(12), @ProteinCollectionID)
						
						UPDATE T_Protein_Collections
						SET Collection_State_ID = 3
						WHERE Protein_Collection_ID = @ProteinCollectionID AND Collection_State_ID = 1

						Exec PostLogEntry 'Normal', @message, 'PromoteProteinCollectionState'
					End
					Else
						Print @message
				
					If Len(@ProteinCollectionsUpdated) > 0
						Set @ProteinCollectionsUpdated = @ProteinCollectionsUpdated + ', '
					
					Set @ProteinCollectionsUpdated = @ProteinCollectionsUpdated + @ProteinCollectionName
					Set @ProteinCollectionCountUpdated = @ProteinCollectionCountUpdated + 1
				End
			End
		End
		
		Set @CurrentLocation = 'Done iterating'

		If @ProteinCollectionCountUpdated = 0
		Begin
			Set @message = 'No protein collections were found with state 1 and jobs defined in DMS'
		End
		Else
		Begin
			-- If more than one collection was affected, update update @message with the overall stats
			If @ProteinCollectionCountUpdated > 1
				Set @message = 'Updated the state for ' + Convert(varchar(12), @ProteinCollectionCountUpdated) + ' protein collections from 1 to 3 since existing jobs were found: ' + @ProteinCollectionsUpdated

		End
		
		If @infoOnly > 0
			Print @message
			
		If @AddNewProteinHeaders <> 0
			Exec AddNewProteinHeaders @InfoOnly = @InfoOnly

			
	End Try
	Begin Catch
		-- Error caught; log the error then abort processing
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'PromoteProteinCollectionState')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
		Goto Done
	End Catch
		
Done:
	Return @myError

GO
