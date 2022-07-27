/****** Object:  StoredProcedure [dbo].[CacheProteinsToMigrate] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CacheProteinsToMigrate]
/****************************************************
**
**  Desc:
**      Populates the T_Migrate tables using protein collections with Migrate_to_Filtered_Tables > 0 in T_Protein_Collections
**
**  Auth:   mem
**  Date:   07/26/2022
**          07/27/2022 mem - Switch from FileName to Collection_Name
**
*****************************************************/
(
    @proteinCollectionIdStart int = 0,          -- If non-zero, start with the given protein collection ID
    @infoOnly tinyint = 0,
    @message varchar(255) = '' output 
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @continue int
    Declare @proteinCollectionID int
    Declare @proteinCollectionName varchar(256)
    Declare @proteinCountTotal int
    Declare @proteinCountCached int

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------
    
    Set @proteinCollectionIdStart = IsNull(@proteinCollectionIdStart, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    Declare @callingProcName varchar(128)
    Declare @currentLocation varchar(128)
    Set @currentLocation = 'Start'

    Begin Try
        If @proteinCollectionIdStart > 0
        Begin
            Set @proteinCollectionID = @proteinCollectionIdStart - 1
        End
        Else
        Begin
            Set @proteinCollectionID = 0
        End

        --------------------------------------------------------------
        -- Loop through protein collections in T_Protein_Collections
        --------------------------------------------------------------
        --
        Set @currentLocation = 'Iterate through the protein collections'
        
        Set @continue = 1
        
        While @continue = 1
        Begin -- <a>

            SELECT TOP 1 @proteinCollectionID = Protein_Collection_ID,
                         @proteinCollectionName = Collection_Name
            FROM T_Protein_Collections
            WHERE Migrate_to_Filtered_Tables > 0 And Protein_Collection_ID > @proteinCollectionID
            ORDER BY Protein_Collection_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            
            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin -- <b>
                SELECT @proteinCountTotal = Count(*)
                FROM T_Protein_Collection_Members
                WHERE Protein_Collection_ID = @proteinCollectionID
                                
                SELECT @proteinCountCached = Count(*)
                FROM T_Migrate_Protein_Collection_Members
                WHERE Protein_Collection_ID = @proteinCollectionID


                If @infoOnly > 0
                Begin
                    Print 'Would store ' + Cast(@proteinCountTotal - @proteinCountCached as Varchar(12)) + ' proteins for protein collection ' + Cast(@proteinCollectionID As Varchar(12)) + ' (' + @proteinCollectionName + ')'
                End
                Else
                Begin -- <c>
                    Print 'Storing ' + Cast(@proteinCountTotal - @proteinCountCached as Varchar(12)) + ' proteins for protein collection ' + Cast(@proteinCollectionID As Varchar(12)) + ' (' + @proteinCollectionName + ')'

                    -- Add protein sequences
                    INSERT INTO T_Migrate_Proteins( Protein_ID,
                                                    Sequence,
                                                    Length,
                                                    Molecular_Formula,
                                                    Monoisotopic_Mass,
                                                    Average_Mass,
                                                    SHA1_Hash,
                                                    DateCreated,
                                                    DateModified,
                                                    IsEncrypted,
                                                    SEGUID )
                    SELECT Protein_ID,
                           Sequence,
                           Length,
                           Molecular_Formula,
                           Monoisotopic_Mass,
                           Average_Mass,
                           SHA1_Hash,
                           DateCreated,
                           DateModified,
                           IsEncrypted,
                           SEGUID
                    FROM T_Proteins
                    WHERE Protein_ID IN ( SELECT P.Protein_ID
                                          FROM T_Protein_Collection_Members PCM
                                               INNER JOIN T_Proteins P
                                                 ON PCM.Protein_ID = P.Protein_ID
                                               LEFT OUTER JOIN T_Migrate_Proteins Target
                                                 ON P.Protein_ID = Target.Protein_ID
                                          WHERE PCM.Protein_Collection_ID = @proteinCollectionID 
                                                AND
                                                Target.Protein_ID IS NULL )

                    -- Add protein names
                    INSERT INTO T_Migrate_Protein_Names( Reference_ID,
                                                         Name,
                                                         Description,
                                                         Annotation_Type_ID,
                                                         Reference_Fingerprint,
                                                         DateAdded,
                                                         Protein_ID )
                    SELECT Reference_ID,
                           Name,
                           Description,
                           Annotation_Type_ID,
                           Reference_Fingerprint,
                           DateAdded,
                           Protein_ID
                    FROM T_Protein_Names
                    WHERE Reference_ID IN ( SELECT N.Reference_ID
                                          FROM T_Protein_Collection_Members PCM
                                               INNER JOIN T_Protein_Names N
                                                 ON PCM.Original_Reference_ID = N.Reference_ID
                                               LEFT OUTER JOIN T_Migrate_Protein_Names Target
                                                 ON N.Reference_ID = Target.Reference_ID
                                          WHERE PCM.Protein_Collection_ID = @proteinCollectionID 
                                                AND
                                                Target.Reference_ID IS NULL )



                    -- Add the protein collection members
                    INSERT INTO T_Migrate_Protein_Collection_Members( Member_ID,
                                                                      Original_Reference_ID,
                                                                      Protein_ID,
                                                                      Protein_Collection_ID,
                                                                      Sorting_Index,
                                                                      Original_Description_ID )
                    SELECT Member_ID,
                           Original_Reference_ID,
                           Protein_ID,
                           Protein_Collection_ID,
                           Sorting_Index,
                           Original_Description_ID
                    FROM T_Protein_Collection_Members
                    WHERE Member_ID IN ( SELECT PCM.Member_ID
                                         FROM T_Protein_Collection_Members PCM
                                              INNER JOIN T_Proteins P
                                                ON PCM.Protein_ID = P.Protein_ID
                                              LEFT OUTER JOIN T_Migrate_Protein_Collection_Members Target
                                                ON PCM.Member_ID = Target.Member_ID
                                         WHERE PCM.Protein_Collection_ID = @proteinCollectionID 
                                               AND
                                               Target.Member_ID IS NULL )

                    -- Add the protein headers
                    Insert Into T_Migrate_Protein_Headers (Protein_ID, Sequence_Head)
                    SELECT Protein_ID,
                           Sequence_Head
                    FROM T_Protein_Headers
                    WHERE Protein_ID IN ( SELECT PH.Protein_ID
                                         FROM T_Protein_Collection_Members PCM
                                              INNER JOIN T_Protein_Headers PH
                                                ON PCM.Protein_ID = PH.Protein_ID
                                              LEFT OUTER JOIN T_Migrate_Protein_Headers Target
                                                ON PCM.Protein_ID = Target.Protein_ID
                                         WHERE PCM.Protein_Collection_ID = @proteinCollectionID 
                                               AND
                                               Target.Protein_ID IS NULL )

                    If Not Exists (Select * From T_Migrate_Protein_Collection_Members_Cached Where Protein_Collection_ID = @proteinCollectionID)
                    Begin
                         -- Add the cached protein collection members
                        INSERT INTO T_Migrate_Protein_Collection_Members_Cached( Protein_Collection_ID,
                                                                                 Reference_ID,
                                                                                 Protein_Name,
                                                                                 Description,
                                                                                 Residue_Count,
                                                                                 Monoisotopic_Mass,
                                                                                 Protein_ID )
                        SELECT Protein_Collection_ID,
                               Reference_ID,
                               Protein_Name,
                               Description,
                               Residue_Count,
                               Monoisotopic_Mass,
                               Protein_ID
                        FROM T_Protein_Collection_Members_Cached
                        WHERE Protein_Collection_ID = @proteinCollectionID
                    End

                End -- </c>
            End -- </b>
        End -- </a>
        
        Set @currentLocation = 'Done iterating'

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @callingProcName = IsNull(ERROR_PROCEDURE(), 'CacheProteinsToMigrate')
        exec LocalErrorHandler  @callingProcName, @currentLocation, @LogError = 1, 
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch
        
Done:
    Return @myError


GO
