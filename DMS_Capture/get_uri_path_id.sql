/****** Object:  StoredProcedure [dbo].[get_uri_path_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_uri_path_id]
/****************************************************
**
**  Desc:   Looks for @URIPath in T_URI_Paths
**          Adds a new row if missing (and @infoOnly = 0)
**
**          Returns the ID of T_URI_Paths in T_URI_Paths
**          Will return 0 if @infoOnly = 1 and a match is not found
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/02/2012 mem - Initial version
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @uriPath varchar(512),
    @infoOnly tinyint = 0
)
AS
    Set nocount on

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0


    ------------------------------------------------
    -- Look for @URIPath in T_URI_Paths
    ------------------------------------------------
    --
    Declare @URI_PathID int
    Set @URI_PathID = 0

    SELECT @URI_PathID = URI_PathID
    FROM T_URI_Paths
    WHERE URI_Path = @URIPath
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0 Or @URI_PathID = 0
    Begin
        ------------------------------------------------
        -- Match not found
        -- Add a new entry (use a Merge in case two separate calls are simultaneously made for the same @URIPath)
        ------------------------------------------------

        If @InfoOnly = 0
        Begin

            MERGE T_URI_Paths AS Target
            USING (
                    SELECT @URIPath
                   ) AS Source (URI_Path)
                ON Source.URI_Path = Target.URI_Path
            WHEN NOT MATCHED BY TARGET THEN
                INSERT ( URI_Path )
                VALUES  ( Source.URI_Path )
            ;

            -- Now that the merge is complete a match should be found
            SELECT @URI_PathID = URI_PathID
            FROM T_URI_Paths
            WHERE URI_Path = @URIPath
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End

    End

    return @URI_PathID

GO
GRANT VIEW DEFINITION ON [dbo].[get_uri_path_id] TO [DDL_Viewer] AS [dbo]
GO
