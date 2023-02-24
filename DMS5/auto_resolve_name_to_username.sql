/****** Object:  StoredProcedure [dbo].[AutoResolveNameToPRN] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoResolveNameToPRN]
/****************************************************
**
**  Desc:   Looks for entries in T_Users that match @nameSearchSpec
**          Updates @matchCount with the number of matching entries
**
**          If more than one entry is found, updates @matchingPRN and @MatchingUserID for the first match
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   02/07/2010
**          01/20/2017 mem - Now checking for names of the form "Last, First (D3P704)" or "Last, First Middle (D3P704)" and auto-fixing those
**          06/12/2017 mem - Check for @nameSearchSpec being a username
**          11/11/2019 mem - Return no matches if @nameSearchSpec is null or an empty string
**          09/11/2020 mem - Use TrimWhitespaceAndPunctuation to remove trailing whitespace and punctuation
**
*****************************************************/
(
    @nameSearchSpec varchar(64),                -- Used to search U_Name in T_Users; use % for a wildcard; note that a % will be appended to @nameSearchSpec if it doesn't end in one
    @matchCount int=0 output,                   -- Number of entries in T_Users that match @nameSearchSpec
    @matchingPRN varchar(64)='' output,         -- If @matchCount > 0, will have the PRN of the first match in T_Users
    @MatchingUserID int=0 output                -- If @matchCount > 0, will have the ID of the first match in T_Users
)
AS
    Set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Set @matchCount = 0

    -- Trim leading and trailing whitespace
    Set @nameSearchSpec= dbo.TrimWhitespaceAndPunctuation(IsNull(@nameSearchSpec, ''))
    If Len(@nameSearchSpec) = 0
    Begin
        Goto Done
    End

    -- Trim leading and trailing punctuation

    If @nameSearchSpec Like '%,%(%)'
    Begin
        -- Name is of the form  "Last, First (D3P704)" or "Last, First Middle (D3P704)"
        -- Extract D3P704

        Declare @charIndexStart int = PatIndex('%(%)%', @nameSearchSpec)
        Declare @charIndexEnd int = CharIndex(')', @nameSearchSpec, @charIndexStart)

        If @charIndexStart > 0
        Begin
            Set @nameSearchSpec = Substring(@nameSearchSpec, @charIndexStart+1, @charIndexEnd-@charIndexStart-1)

            SELECT @matchingPRN = U_PRN,
                   @MatchingUserID = ID
            FROM T_Users
            WHERE U_PRN = @nameSearchSpec
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @matchCount = 1
                Goto Done
            End
        End
    End

    If Not @nameSearchSpec LIKE '%[%]'
    Begin
        Set @nameSearchSpec = @nameSearchSpec + '%'
    End

    SELECT @matchCount = COUNT(*)
    FROM T_Users
    WHERE U_Name LIKE @nameSearchSpec
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError = 0 And @matchCount > 0
    Begin
        -- Update @matchingPRN and @MatchingUserID
        SELECT TOP 1 @matchingPRN = U_PRN,
                     @MatchingUserID = ID
        FROM T_Users
        WHERE U_Name LIKE @nameSearchSpec
        ORDER BY ID

    End

    If @matchCount = 0
    Begin
        -- Check @nameSearchSpec against the U_PRN column
        SELECT @matchCount = COUNT(*)
        FROM T_Users
        WHERE U_PRN LIKE @nameSearchSpec
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError = 0 And @matchCount > 0
        Begin
            -- Update @matchingPRN and @MatchingUserID
            SELECT TOP 1 @matchingPRN = U_PRN,
                         @MatchingUserID = ID
            FROM T_Users
            WHERE U_PRN LIKE @nameSearchSpec
            ORDER BY ID
        End

    End

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AutoResolveNameToPRN] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AutoResolveNameToPRN] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AutoResolveNameToPRN] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AutoResolveNameToPRN] TO [Limited_Table_Write] AS [dbo]
GO
