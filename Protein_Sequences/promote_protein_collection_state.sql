/****** Object:  StoredProcedure [dbo].[PromoteProteinCollectionState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PromoteProteinCollectionState]
/****************************************************
**
**  Desc:   Examines protein collections with a state of 1
**
**          Looks in MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
**          for any analysis jobs that refer to the given
**          protein collection.  If any are found, the state
**          for the given protein collection is changed to 3
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/13/2007
**          04/08/2008 mem - Added parameter @addNewProteinHeaders
**          02/23/2016 mem - Add set XACT_ABORT on
**          09/12/2016 mem - Add parameter @mostRecentMonths
**          07/27/2022 mem - Adjust case of variable names
**
*****************************************************/
(
    @addNewProteinHeaders tinyint = 1,
    @mostRecentMonths int = 12,            -- Used to filter protein collections that we will examine
    @infoOnly tinyint = 0,
    @message varchar(255) = '' output 
)
AS

    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @continue int
    Declare @proteinCollectionID int
    Declare @proteinCollectionName varchar(128)

    Declare @nameFilter varchar(256)
    Declare @jobCount int
    
    Declare @proteinCollectionsUpdated varchar(max)
    Declare @proteinCollectionCountUpdated int
    
    Set @proteinCollectionCountUpdated = 0
    Set @proteinCollectionsUpdated = ''
    
    Set @message = ''

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------
    
    Set @addNewProteinHeaders = IsNull(@addNewProteinHeaders, 1)

    Set @mostRecentMonths = IsNull(@mostRecentMonths, 12)
    If @mostRecentMonths <= 0
        Set @mostRecentMonths = 12

    If @mostRecentMonths > 2000
        Set @mostRecentMonths = 2000

    Set @infoOnly = IsNull(@infoOnly, 0)

    --------------------------------------------------------------
    -- Loop through the protein collections with a state of 1
    -- Limit to protein collections created within the last @mostRecentMonths months
    --------------------------------------------------------------
    --
    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128) = 'Start'

    Begin Try
        
        Set @proteinCollectionID = 0
        Set @continue = 1
        
        While @continue = 1
        Begin
            Set @CurrentLocation = 'Find the next Protein collection with state 1'
            
            SELECT TOP 1 @proteinCollectionID = Protein_Collection_ID, 
                         @proteinCollectionName = Collection_Name
            FROM T_Protein_Collections
            WHERE Collection_State_ID = 1 AND
                  Protein_Collection_ID > @proteinCollectionID AND
                  DateCreated >= DATEADD(month, -@mostRecentMonths, GETDATE())
            ORDER BY Protein_Collection_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            If @myRowCount <> 1
                Set @continue = 0
            Else
            Begin
                Set @CurrentLocation = 'Look for jobs in V_DMS_Analysis_Job_Info that used ' + @proteinCollectionName

                If @infoOnly > 0
                    Print @CurrentLocation

                Set @nameFilter = '%' + @proteinCollectionName + '%'
                
                Set @jobCount = 0

                SELECT @jobCount = COUNT(*)
                FROM MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
                WHERE ProteinCollectionList LIKE @nameFilter
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                
                If @jobCount > 0
                Begin
                    Set @message = 'Updated state for Protein Collection "' + @proteinCollectionName + '" from 1 to 3 since ' + Convert(varchar(12), @jobCount) + ' jobs are defined in DMS with this protein collection'

                    If @infoOnly = 0
                    Begin
                        Set @CurrentLocation = 'Update state for CollectionID ' + Convert(varchar(12), @proteinCollectionID)
                        
                        UPDATE T_Protein_Collections
                        SET Collection_State_ID = 3
                        WHERE Protein_Collection_ID = @proteinCollectionID AND Collection_State_ID = 1

                        Exec PostLogEntry 'Normal', @message, 'PromoteProteinCollectionState'
                    End
                    Else
                        Print @message
                
                    If Len(@proteinCollectionsUpdated) > 0
                        Set @proteinCollectionsUpdated = @proteinCollectionsUpdated + ', '
                    
                    Set @proteinCollectionsUpdated = @proteinCollectionsUpdated + @proteinCollectionName
                    Set @proteinCollectionCountUpdated = @proteinCollectionCountUpdated + 1
                End
            End
        End
        
        Set @CurrentLocation = 'Done iterating'

        If @proteinCollectionCountUpdated = 0
        Begin
            Set @message = 'No protein collections were found with state 1 and jobs defined in DMS'
        End
        Else
        Begin
            -- If more than one collection was affected, update update @message with the overall stats
            If @proteinCollectionCountUpdated > 1
                Set @message = 'Updated the state for ' + Convert(varchar(12), @proteinCollectionCountUpdated) + ' protein collections from 1 to 3 since existing jobs were found: ' + @proteinCollectionsUpdated
        End
        
        If @infoOnly > 0
            Print @message
            
        If @addNewProteinHeaders <> 0
            Exec AddNewProteinHeaders @infoOnly = @infoOnly
            
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
