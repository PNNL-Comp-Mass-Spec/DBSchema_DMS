/****** Object:  StoredProcedure [dbo].[promote_protein_collection_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[promote_protein_collection_state]
/****************************************************
**
**  Desc:
**      Look for protein collections with a state of 1 in T_Protein_Collections
**
**      For each, look for analysis jobs in MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached that use the given protein collection
**      If any jobs are found, update the protein collection state to 3
**
**      If @addNewProteinHeaders is non-zero, call add_new_protein_headers to add new rows to T_Protein_Headers
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/13/2007
**          04/08/2008 mem - Added parameter @addNewProteinHeaders
**          02/23/2016 mem - Add set XACT_ABORT on
**          09/12/2016 mem - Add parameter @mostRecentMonths
**          07/27/2022 mem - Adjust case of variable names
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/09/2024 mem - Cache protein collection lists in a temporary table, removing the need to re-query T_DMS_Analysis_Job_Info_Cached for each protein collection
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

    Declare @proteinCollectionsUpdated varchar(max) = ''
    Declare @proteinCollectionCountUpdated int = 0


    Set @message = ''

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    Set @addNewProteinHeaders = IsNull(@addNewProteinHeaders, 1)

    Set @mostRecentMonths = IsNull(@mostRecentMonths, 12)

    If @mostRecentMonths <= 0
        Set @mostRecentMonths = 12

    Set @infoOnly = IsNull(@infoOnly, 0)

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128) = 'Start'

    Begin Try

        If Exists (SELECT Protein_Collection_ID
                   FROM T_Protein_Collections
                   WHERE Collection_State_ID = 1 AND
                         DateCreated >= DATEADD(month, -@mostRecentMonths, GETDATE()))
        Begin
            --------------------------------------------------------------
            -- Cache the protein collection lists used by analysis jobs
            --------------------------------------------------------------

            -- This table has an identity column as the primary key since
            -- SQL Server does not allow a field larger than varchar(900) to be a primary key (or to be indexed)
            CREATE TABLE #Tmp_Analysis_Job_Protein_Collections (
                Collection_List_ID int identity(1,1) PRIMARY KEY,
                Protein_Collection_List varchar(2000) NOT NULL,
                Jobs int NOT NULL
            )

            INSERT INTO #Tmp_Analysis_Job_Protein_Collections (Protein_Collection_List, Jobs)
            SELECT ProteinCollectionList, COUNT(*) AS Jobs
            FROM MT_Main.dbo.T_DMS_Analysis_Job_Info_Cached
            WHERE NOT ProteinCollectionList Is Null
            GROUP BY ProteinCollectionList
            ORDER BY ProteinCollectionList;

            --------------------------------------------------------------
            -- Loop through the protein collections with a state of 1
            -- Limit to protein collections created within the last @mostRecentMonths months
            --------------------------------------------------------------

            Set @proteinCollectionID = 0
            Set @continue = 1

            While @continue = 1
            Begin
                Set @CurrentLocation = 'Find the next protein collection with state 1'

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
                    Set @CurrentLocation = 'Look for jobs that used ' + @proteinCollectionName

                    If @infoOnly > 0
                        Print @CurrentLocation

                    Set @nameFilter = '%' + @proteinCollectionName + '%'

                    Set @jobCount = 0

                    SELECT @jobCount = SUM(Jobs)
                    FROM #Tmp_Analysis_Job_Protein_Collections
                    WHERE Protein_Collection_List LIKE @nameFilter
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @jobCount > 0
                    Begin
                        If @infoOnly = 0
                            Set @message = 'Updated'
                        Else
                            Set @message = 'Would update'

                        Set @message = @message + ' state for Protein Collection "' + @proteinCollectionName + '" from 1 to 3 since ' + Convert(varchar(12), @jobCount) + ' jobs are defined in DMS with this protein collection'

                        If @infoOnly = 0
                        Begin
                            Set @CurrentLocation = 'Update state for CollectionID ' + Convert(varchar(12), @proteinCollectionID)

                            UPDATE T_Protein_Collections
                            SET Collection_State_ID = 3
                            WHERE Protein_Collection_ID = @proteinCollectionID AND Collection_State_ID = 1

                            Exec post_log_entry 'Normal', @message, 'promote_protein_collection_state'
                        End
                        Else
                        Begin
                            Print @message
                        End

                        If Len(@proteinCollectionsUpdated) > 0
                            Set @proteinCollectionsUpdated = @proteinCollectionsUpdated + ', '

                        Set @proteinCollectionsUpdated = @proteinCollectionsUpdated + @proteinCollectionName
                        Set @proteinCollectionCountUpdated = @proteinCollectionCountUpdated + 1
                    End
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
            Exec add_new_protein_headers @infoOnly = @infoOnly

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'promote_protein_collection_state')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch

Done:
    Return @myError

GO