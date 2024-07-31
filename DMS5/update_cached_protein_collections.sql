/****** Object:  StoredProcedure [dbo].[update_cached_protein_collections] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_cached_protein_collections]
/****************************************************
**
**  Desc:   Updates the data in T_Cached_Protein_Collections
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/13/2016 mem - Initial Version
**          10/23/2017 mem - Use S_V_Protein_Collections_by_Organism instead of S_V_Protein_Collection_Picker since S_V_Protein_Collection_Picker only includes active protein collections
**          08/30/2021 mem - Populate field State_Name
**          07/27/2022 mem - Use new field names when querying S_V_Protein_Collections_by_Organism (Collection_Name instead of FileName and File_Size instead of Filesize)
**          01/06/2023 mem - Use new colunmn name in view
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/30/2024 mem - Populate field Collection_State_ID
**
*****************************************************/
(
    @message varchar(255) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Set @message = ''

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try
        Set @CurrentLocation = 'Update T_Cached_Protein_Collections'
        --

        MERGE dbo.T_Cached_Protein_Collections AS t
        USING (SELECT Protein_Collection_ID AS ID, Organism_ID,
                      Collection_Name AS Name, Description,
                      Collection_State_ID, State_Name,
                      NumProteins AS Entries, NumResidues AS Residues,
                      [Type], File_Size_Bytes
               FROM dbo.S_V_Protein_Collections_by_Organism) as s
        ON ( t.ID = s.ID AND t.Organism_ID = s.Organism_ID)
        WHEN MATCHED AND (
            t.Name <> s.Name OR
            ISNULL( NULLIF(t.Description, s.Description),
                    NULLIF(s.Description, t.Description)) IS NOT NULL OR
            ISNULL( NULLIF(t.Collection_State_ID, s.Collection_State_ID),
                    NULLIF(s.Collection_State_ID, t.Collection_State_ID)) IS NOT NULL OR
            ISNULL( NULLIF(t.State_Name, s.State_Name),
                    NULLIF(s.State_Name, t.State_Name)) IS NOT NULL OR
            ISNULL( NULLIF(t.Entries, s.Entries),
                    NULLIF(s.Entries, t.Entries)) IS NOT NULL OR
            ISNULL( NULLIF(t.Residues, s.Residues),
                    NULLIF(s.Residues, t.Residues)) IS NOT NULL OR
            ISNULL( NULLIF(t.[Type], s.[Type]),
                    NULLIF(s.[Type], t.[Type])) IS NOT NULL OR
            ISNULL( NULLIF(t.Filesize, s.File_Size_Bytes),
                    NULLIF(s.File_Size_Bytes, t.Filesize)) IS NOT NULL
            )
        THEN UPDATE Set
            Name = s.Name,
            Description = s.Description,
            Collection_State_ID = s.Collection_State_ID,
            State_Name = s.State_Name,
            Entries = s.Entries,
            Residues = s.Residues,
            [Type] = s.[Type],
            Filesize = s.File_Size_Bytes,
            Last_Affected = GetDate()
        WHEN NOT MATCHED BY TARGET THEN
            INSERT(ID, Organism_ID, Name, Description, Collection_State_ID, State_Name, Entries, Residues, [Type], Filesize, Created, Last_Affected)
            VALUES(s.ID, s.Organism_ID, s.Name, s.Description, s.Collection_State_ID, s.State_Name, s.Entries, s.Residues, s.[Type], s.File_Size_Bytes, GetDate(), GetDate())
        WHEN NOT MATCHED BY SOURCE THEN DELETE
        ;

        If @myError <> 0
        Begin
            Set @message = 'Error updating T_Cached_Protein_Collections via merge (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute post_log_entry 'Error', @message, 'update_cached_protein_collections'
            goto Done
        End

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_cached_protein_collections')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_cached_protein_collections] TO [DDL_Viewer] AS [dbo]
GO
