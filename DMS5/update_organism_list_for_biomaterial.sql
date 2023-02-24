/****** Object:  StoredProcedure [dbo].[UpdateOrganismListForBiomaterial] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateOrganismListForBiomaterial]
/****************************************************
**
**  Desc: Updates organisms associated with a single biomaterial (cell_culture) item
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          09/06/2018 mem - Fix delete bug in Merge statement
**          03/31/2021 mem - Expand Organism_Name, @unknownOrganism, and @newOrganismName to varchar(128)
**
*****************************************************/
(
    @biomaterialName varchar(64),      -- Biomaterial name, aka cell culture
    @organismList varchar(max),        -- Comma-separated list of organism names.  Should be full organism name, but can also be short names, in which case AutoResolveOrganismName will try to resolve the short name to a full organsim name
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @biomaterialID int = 0
    Declare @entryID int
    Declare @continue tinyint

    Declare @matchCount int
    Declare @unknownOrganism varchar(128)
    Declare @newOrganismName varchar(128)
    Declare @newOrganismID int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateOrganismListForBiomaterial', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Resolve biomaterial name to ID
    ---------------------------------------------------
    --
    SELECT @biomaterialID = CC_ID
    FROM T_Cell_Culture
    WHERE CC_Name = @biomaterialName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message= 'Error trying to resolve biomaterial ID (cell culture ID'
        Goto Done
    End

    If IsNull(@biomaterialID, 0) = 0
    Begin
        set @message = 'Cannot update organisms for biomaterial: "' + @biomaterialName + '" does not exist'
        Goto Done
    End

    If @organismList Is Null
    Begin
        set @message= 'Cannot update biomaterial "' + @biomaterialName + '": organism list cannot be null'
        Goto Done
    End

    Set @organismList = LTrim(RTrim(@organismList))
    If @organismList = ''
    Begin
        -- Empty organism list; make sure no rows exist in T_Biomaterial_Organisms for this biomaterial item
        --
        DELETE FROM T_Biomaterial_Organisms
        WHERE Biomaterial_ID = @biomaterialID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        UPDATE T_Cell_Culture
        Set Cached_Organism_List = ''
        WHERE CC_ID = @biomaterialID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        GOTO Done
    End

    ---------------------------------------------------
    -- Create a temp table to hold the list of organism names and IDs for this biomaterial item
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_BiomaterialOrganisms (
        Organism_Name varchar(128) not null,
        Organism_ID int null,
        EntryID int Identity(1,1)
    )

    ---------------------------------------------------
    -- Parse the comma-separated list of organism names supplied by the user
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_BiomaterialOrganisms ( Organism_Name )
    SELECT Item
    FROM dbo.MakeTableFromList(@organismList) AS Organisms
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error parsing the comma-separated list of organism names'
        Goto Done
    End

    ---------------------------------------------------
    -- Resolve the organism ID for the organism names
    ---------------------------------------------------
    --
    UPDATE #Tmp_BiomaterialOrganisms
    SET Organism_ID = Org.Organism_ID
    FROM #Tmp_BiomaterialOrganisms
         INNER JOIN dbo.T_Organisms Org
           ON #Tmp_BiomaterialOrganisms.Organism_Name = Org.OG_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error resolving organism ID'
        Goto Done
    End

    ---------------------------------------------------
    -- Look for entries in #Tmp_BiomaterialOrganisms where Organism_Name did not resolve to an Organism_ID
    -- In case a portion of an organism name was entered, or in case a short name was used,
    -- try-to auto-resolve using the OG_Name column in T_Organisms
    ---------------------------------------------------

    Set @entryID = 0
    Set @continue = 1

    While @continue = 1
    Begin -- <a>
        SELECT TOP 1 @entryID = EntryID,
                     @unknownOrganism = Organism_Name
        FROM #Tmp_BiomaterialOrganisms
        WHERE EntryID > @entryID AND Organism_ID IS NULL
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin -- <b>
            Set @matchCount = 0

            exec AutoResolveOrganismName @unknownOrganism, @matchCount output, @newOrganismName output, @newOrganismID output

            If @matchCount = 1
            Begin
                -- Single match was found; update Organism_Name and Organism_ID in #Tmp_BiomaterialOrganisms
                UPDATE #Tmp_BiomaterialOrganisms
                SET Organism_Name = @newOrganismName,
                    Organism_ID = @newOrganismID
                WHERE EntryID = @entryID

            End
        End -- </b>
    End -- </a>

    ---------------------------------------------------
    -- Error if any of the organism names could not be resolved
    ---------------------------------------------------
    --
    Declare @list varchar(512) = ''
    --
    SELECT
        @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + Organism_Name
    FROM #Tmp_BiomaterialOrganisms
    WHERE Organism_ID IS NULL
    ORDER BY Organism_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error checking for unresolved organism ID'
        Goto Done
    End
    --
    If @list <> ''
    Begin
        set @message = 'Could not resolve the following organism names: ' + @list
        set @myError = 51000
        Goto Done
    End

    ---------------------------------------------------
    -- Update the organisms using a merge statement
    ---------------------------------------------------
    --
    MERGE dbo.T_Biomaterial_Organisms AS t
    USING (SELECT @biomaterialID as Biomaterial_ID, Organism_ID FROM #Tmp_BiomaterialOrganisms) as s
    ON ( t.Biomaterial_ID = s.Biomaterial_ID AND t.Organism_ID = s.Organism_ID)
    -- Note: all of the columns in table T_Biomaterial_Organisms are primary keys or identity columns; there are no updatable columns
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(Biomaterial_ID, Organism_ID)
        VALUES(s.Biomaterial_ID, s.Organism_ID)
    WHEN NOT MATCHED BY SOURCE And t.Biomaterial_ID = @biomaterialID THEN DELETE;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error updating the biomaterial to organism mapping'
        Goto Done
    End

    ---------------------------------------------------
    -- Update Cached_Organism_List
    ---------------------------------------------------
    --
    UPDATE T_Cell_Culture
    Set Cached_Organism_List = dbo.GetBiomaterialOrganismList(@biomaterialID)
    WHERE CC_ID = @biomaterialID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

Done:

    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512) = ''
    Set @usageMessage = 'Biomaterial: ' + @biomaterialName
    Exec PostUsageLogEntry 'UpdateOrganismListForBiomaterial', @usageMessage

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateOrganismListForBiomaterial] TO [DDL_Viewer] AS [dbo]
GO
