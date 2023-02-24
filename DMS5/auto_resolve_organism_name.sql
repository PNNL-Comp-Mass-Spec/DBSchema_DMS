/****** Object:  StoredProcedure [dbo].[auto_resolve_organism_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_resolve_organism_name]
/****************************************************
**
**  Desc:   Looks for entries in T_Organisms that match @nameSearchSpec
**          First checks OG_name then checks OG_Short_Name
**          Updates @matchCount with the number of matching entries
**
**          If one more more entries is found, updates @matchingOrganismName and @matchingOrganismID for the first match
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial Version
**          03/31/2021 mem - Expand @nameSearchSpec and @matchingOrganismName to varchar(128)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @nameSearchSpec varchar(128),                    -- Used to search OG_name and OG_Short_Name in T_Organisms; use % for a wildcard; note that a % will be appended to @nameSearchSpec if it doesn't end in one
    @matchCount int=0 output,                        -- Number of entries in T_Organisms that match @nameSearchSpec
    @matchingOrganismName varchar(128) = '' output,    -- If @nameSearchSpec > 0, then the Organism name of the first match in T_Organisms
    @matchingOrganismID int=0 output                -- If @nameSearchSpec > 0, then the ID of the first match in T_Organisms
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @matchCount = 0

    If Not @nameSearchSpec LIKE '%[%]'
    Begin
        Set @nameSearchSpec = @nameSearchSpec + '%'
    End

    SELECT @matchCount = COUNT(*)
    FROM T_Organisms
    WHERE OG_name LIKE @nameSearchSpec
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError = 0 And @matchCount > 0
    Begin
        -- Update @matchingOrganismName and @matchingOrganismID
        --
        SELECT TOP 1 @matchingOrganismName = OG_name,
                     @matchingOrganismID = Organism_ID
        FROM T_Organisms
        WHERE OG_name LIKE @nameSearchSpec
        ORDER BY Organism_ID
    End

    If @myError = 0 And @matchCount = 0
    Begin
        SELECT @matchCount = COUNT(*)
        FROM T_Organisms
        WHERE OG_Short_Name LIKE @nameSearchSpec
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError = 0 And @matchCount > 0
        Begin
            -- Update @matchingOrganismName and @matchingOrganismID
            --
            SELECT TOP 1 @matchingOrganismName = OG_name,
                         @matchingOrganismID = Organism_ID
            FROM T_Organisms
            WHERE OG_Short_Name LIKE @nameSearchSpec
            ORDER BY Organism_ID
        End
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[auto_resolve_organism_name] TO [DDL_Viewer] AS [dbo]
GO
