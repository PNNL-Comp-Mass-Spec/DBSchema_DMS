/****** Object:  StoredProcedure [dbo].[UpdateDatasetRating] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateDatasetRating]
/****************************************************
**
**  Desc:   Updates the rating for the given datasets by calling SP UpdateDatasets
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   10/07/2015 mem - Initial release
**          03/17/2017 mem - Pass this procedure's name to udfParseDelimitedList
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @datasets varchar(6000),                -- Comma-separated list of datasets
    @rating varchar(32) = 'Unknown',        -- Typically "Released" or "Not Released"
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    Set @rating = IsNull(@rating, '')
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'UpdateDatasetRating', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Resolve id for rating
    ---------------------------------------------------

    Declare @ratingID int

    execute @ratingID = GetDatasetRatingID @rating
    if @ratingID = 0
    begin
        Set @message = 'Could not find entry in database for rating "' + @rating + '"'
        Print @message
        Goto Done
    end

    Declare @DatasetCount int = 0

    SELECT @DatasetCount= COUNT (DISTINCT Value)
    FROM udfParseDelimitedList(@datasets, ',', 'UpdateDatasetRating')

    If @DatasetCount = 0
    Begin
        Set @message = '@datasets cannot be empty'
        Set @myError = 10
        Goto Done
    End

    ---------------------------------------------------
    -- Determine the mode based on @infoOnly
    ---------------------------------------------------

    Declare @mode varchar(12) = 'update'
    If @infoOnly <> 0
        Set @mode = 'preview'

    ---------------------------------------------------
    -- Call stored procedure UpdateDatasets
    ---------------------------------------------------

    Exec @myError = UpdateDatasets @datasets, @rating=@rating, @mode=@mode, @message=@message output, @callingUser=@callingUser

    If @myError = 0 And @infoOnly = 0
    Begin
        If @DatasetCount = 1
            Set @message = 'Changed the rating to "' + @rating + '" for dataset ' + @datasets
        Else
            Set @message = 'Changed the rating to "' + @rating + '" for ' + Cast(@DatasetCount as varchar(12)) + ' datasets'

        SELECT @message as Message, @datasets as DatasetList
    End

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetRating] TO [DDL_Viewer] AS [dbo]
GO
