/****** Object:  StoredProcedure [dbo].[auto_resolve_organism_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_resolve_organism_name]
/****************************************************
**
**  Desc:
**      Look for entries in T_Organisms that match @nameSearchSpec
**      First check OG_name then check OG_Short_Name
**
**      Search logic:
**      - Check for an exact match to @nameSearchSpec, which allows for matching organism 'Mus_musculus' even though we have other organisms whose names start with Mus_musculus
**      - If no match, but @nameSearchSpec contains a % sign, check whether it matches a single organism
**      - If no match, append a % sign and check again
**
**      If one more more entries is found, update @matchingOrganismName and @matchingOrganismID with the first match
**
**  Arguments:
**    @nameSearchSpec         Organism name to find; use % for a wildcard; note that a % will be appended to @nameSearchSpec if an exact match is not found
**    @matchCount             Output: Number of entries in t_organisms that match @nameSearchSpec
**    @matchingOrganismName   Output: If @nameSearchSpec > 0, the organism name of the first match in t_organisms
**    @matchingOrganismID     Output: If @nameSearchSpec > 0, the organism ID of the first match
**
**  Auth:   mem
**  Date:   12/02/2016 mem - Initial Version
**          03/31/2021 mem - Expand @nameSearchSpec and @matchingOrganismName to varchar(128)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          12/30/2023 mem - Update logic for finding a matching organism (see above)
**
*****************************************************/
(
    @nameSearchSpec varchar(128),
    @matchCount int=0 output,
    @matchingOrganismName varchar(128) = '' output,
    @matchingOrganismID int=0 output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate @nameSearchSpec and initialize the outputs
    ---------------------------------------------------

    Set @nameSearchSpec = LTrim(RTrim(Coalesce(@nameSearchSpec, '')))
    Set @matchCount = 0
    Set @matchingOrganismName = ''
    Set @matchingOrganismID = 0

    Declare @currentSearchSpec varchar(256)
    Declare @iteration int = 1

    While @iteration <= 3
    Begin
        If @iteration = 1
        Begin
            Set @currentSearchSpec = @nameSearchSpec;
        End
        Else If @iteration = 2
        Begin
            If CHARINDEX('%', @nameSearchSpec) = 0
            Begin
                -- Wildcard symbol not found
                -- Move on to the next iteration by setting @currentSearchSpec to an empty string
                Set @currentSearchSpec = ''
            End
            Else
            Begin
                Set @currentSearchSpec = @nameSearchSpec;
            End
        End
        Else
        Begin
            If @nameSearchSpec LIKE '%[%]'
                Set @currentSearchSpec = @nameSearchSpec;
            Else
                Set @currentSearchSpec = @nameSearchSpec + '%';
        End

        If Len(@currentSearchSpec) > 0
        Begin

            SELECT @matchCount = COUNT(*)
            FROM T_Organisms
            WHERE OG_name LIKE @currentSearchSpec
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError = 0 And (@iteration <= 2 And @matchcount = 1 Or @iteration > 2 And @matchcount > 0)
            Begin
                -- Update @matchingOrganismName and @matchingOrganismID

                SELECT TOP 1 @matchingOrganismName = OG_name,
                             @matchingOrganismID = Organism_ID
                FROM T_Organisms
                WHERE OG_name LIKE @currentSearchSpec
                ORDER BY Organism_ID;

                Return 0;
            End

            SELECT @matchCount = COUNT(*)
            FROM T_Organisms
            WHERE OG_Short_Name LIKE @currentSearchSpec
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError = 0 And (@iteration <= 2 And @matchcount = 1 Or @iteration > 2 And @matchcount > 0)
            Begin
                -- Update @matchingOrganismName and @matchingOrganismID

                SELECT TOP 1 @matchingOrganismName = OG_name,
                             @matchingOrganismID = Organism_ID
                FROM T_Organisms
                WHERE OG_Short_Name LIKE @currentSearchSpec
                ORDER BY Organism_ID

                Return 0
            End
        End

        Set @iteration = @iteration + 1
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[auto_resolve_organism_name] TO [DDL_Viewer] AS [dbo]
GO
