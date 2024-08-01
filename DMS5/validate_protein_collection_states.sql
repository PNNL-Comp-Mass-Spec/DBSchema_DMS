/****** Object:  StoredProcedure [dbo].[validate_protein_collection_states] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_protein_collection_states]
/****************************************************
**
**  Desc:
**      Validate the collection states for protein collections in temporary table Tmp_ProteinCollections
**
**      The calling procedure must create and populate a temporary table that includes columns Protein_Collection_Name and Collection_State_ID
**      (this procedure updates values in column Collection_State_ID, so the calling procedure need only store protein collection names, but can store 0 for the states)
**
**      CREATE TABLE #Tmp_ProteinCollections (
**          Protein_Collection_Name varchar(128) NOT NULL,
**          Collection_State_ID int NOT NULL
**      );
**
**  Arguments:
**    @invalidCount     Output: Number of invalid protein collections (unrecognized name or protein collection with state 5 = Proteins_Deleted)
**    @offlineCount     Output: Number of offline protein collections (protein collection with state 6 = Offline; protein names and sequences are no longer in the pc.t_protein tables)
**    @message          Warning message(s); empty string if no issues
**    @showDebug        When true, show @message if not an empty string
**
**  Auth:   mem
**  Date:   07/30/2024 mem - Initial release
**          08/01/2024 mem - Ignore protein collections named 'na'
**
*****************************************************/
(
    @invalidCount int = 0 output,
    @offlineCount int = 0 output,
    @message varchar(256) = '' output,
    @showDebug tinyint = 0
)
AS
    Set Nocount On

    Declare @myError int = 0
    Declare @myRowCount int = 0
    Declare @returnCode int = 0
    Declare @msg varchar(512)

    Set @message = ''

    --------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------

    Set @invalidCount = 0;
    Set @offlineCount = 0;
    Set @showDebug    = Coalesce(@showDebug, 0);

    --------------------------------------------------------------
    -- Lookup the state of each protein collection
    --------------------------------------------------------------

    UPDATE #Tmp_ProteinCollections
    SET Collection_State_ID = PC.collection_state_id
    FROM T_Cached_Protein_Collections PC
    WHERE #Tmp_ProteinCollections.Protein_Collection_Name = PC.Name AND
          Not PC.collection_state_id Is Null;

    --------------------------------------------------------------
    -- Count collections with specific states
    --------------------------------------------------------------

    SELECT @invalidCount = COUNT(*)
    FROM #Tmp_ProteinCollections
    WHERE Collection_State_ID IN (0, 5) AND Not Protein_Collection_Name IN ('na');

    SELECT @offlineCount = COUNT(*)
    FROM #Tmp_ProteinCollections
    WHERE Collection_State_ID IN (6) AND Not Protein_Collection_Name IN ('na');

    --------------------------------------------------------------
    -- Look for unrecognized protein collections
    --------------------------------------------------------------

    Set @msg = Null

    SELECT @msg = Coalesce(@msg + ', ' + Protein_Collection_Name, Protein_Collection_Name)
    FROM #Tmp_ProteinCollections
    WHERE Collection_State_ID = 0 AND Not Protein_Collection_Name IN ('na')
    ORDER BY Protein_Collection_Name;

    If @msg <> ''
    Begin
        Set @msg = 'Unrecognized protein ' + CASE WHEN CharIndex(',', @msg) > 0 THEN 'collections' ELSE 'collection' END + ' ' + @msg;

        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024);

        If @returnCode = 0
        Begin
            Set @returnCode = 5480;
        End
    End

    --------------------------------------------------------------
    -- Look for protein collections with state 'Proteins_Deleted'
    --------------------------------------------------------------

    Set @msg = Null

    SELECT @msg = Coalesce(@msg + ', ' + Protein_Collection_Name, Protein_Collection_Name)
    FROM #Tmp_ProteinCollections
    WHERE Collection_State_ID = 5;

    If @msg <> ''
    Begin
        Set @msg = 'Cannot use deleted protein ' + CASE WHEN CharIndex(',', @msg) > 0 THEN 'collections' ELSE 'collection' END + ' ' + @msg;

        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024);

        If @returnCode = 0
        Begin
            Set @returnCode = 5481;
        End
    End

    --------------------------------------------------------------
    -- Look for protein collections with state 'Offline'
    --------------------------------------------------------------

    Set @msg = Null

    SELECT @msg = Coalesce(@msg + ', ' + Protein_Collection_Name, Protein_Collection_Name)
    FROM #Tmp_ProteinCollections
    WHERE Collection_State_ID = 6;

    If @msg <> ''
    Begin
        Set @msg = CASE WHEN CharIndex(',', @msg) > 0
                        THEN 'Cannot use offline protein collections (collections not used recently)'
                        ELSE 'Cannot use an offline protein collection (not used recently)'
                   END +
                   ': ' + @msg + ' (contact an admin to restore the proteins)'

        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024);

        If @returnCode = 0
        Begin
            Set @returnCode = 5482;
        End
    End

    If @showDebug <> 0
    Begin
        Print @message;
    End

    Return @returnCode

GO
GRANT VIEW DEFINITION ON [dbo].[validate_protein_collection_states] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_protein_collection_states] TO [Limited_Table_Write] AS [dbo]
GO
