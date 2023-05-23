/****** Object:  StoredProcedure [dbo].[add_update_material_container] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_material_container]
/****************************************************
**
**  Desc: Adds new or edits an existing material container
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/20/2008 grk - Initial release
**          07/18/2008 grk - Added checking for location's container limit
**          11/25/2008 grk - Corrected update not to check for room if location doesn't change
**          07/28/2011 grk - Added owner field
**          08/01/2011 grk - Always create new container if mode is "add"
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Validate inputs
**          12/19/2018 mem - Standardize the researcher name
**          11/11/2019 mem - If @researcher is 'na' or 'none', store an empty string in the Researcher column of T_Material_Containers
**          07/02/2021 mem - Require that the researcher is a valid DMS user
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/23/2023 mem - Use a Like clause to prevent updating Staging containers
**
*****************************************************/
(
    @container varchar(128) output,
    @type varchar(32),              -- Box, Bag, or Wellplate
    @location varchar(24),
    @comment varchar(1024),
    @barcode varchar(32),
    @researcher varchar(128),       -- Supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
    @mode varchar(12) = 'add',      -- 'Add', 'update', or 'preview'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @Status varchar(32) = 'Active'

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_material_container', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Make sure the inputs are not null
    -- Additional validation occurs later
    ---------------------------------------------------

    Set @container = LTrim(RTrim(IsNull(@container, '')))
    Set @type = LTrim(RTrim(IsNull(@type, 'Box')))
    Set @location = LTrim(RTrim(IsNull(@location, '')))
    Set @comment = LTrim(RTrim(IsNull(@comment, '')))
    Set @barcode = LTrim(RTrim(IsNull(@barcode, '')))
    Set @researcher = LTrim(RTrim(IsNull(@researcher, '')))
    Set @mode = IsNull(@mode, '')

    ---------------------------------------------------
    -- Optionally generate a container name
    ---------------------------------------------------

    If @container = '(generate name)' OR @mode = 'add'
    Begin
        Declare @tmp int
        --
        SELECT @tmp = MAX(ID) + 1
        FROM  T_Material_Containers
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error trying to auto-generate the container name'
            Return 51000
        End

        Set @container = 'MC-' + cast(@tmp as varchar(12))
    End

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If Len(@container) = 0
    Begin
        Set @message = 'Container name cannot be empty'
        Return 51002
    End

    If @container = 'na' Or @container Like '%Staging%'
    Begin
        Set @message = 'The "' + @container + '" container cannot be updated via the website; contact a DMS admin (see add_update_material_container)'
        Return 51003
    End

    If @mode = 'add' And Not @type In ('Box', 'Bag', 'Wellplate')
    Begin
        Set @type = 'Box'
    End

    If Not @type In ('Box', 'Bag', 'Wellplate')
    Begin
        Set @message = 'Container type must be Box, Bag, or Wellplate, not ' + @type
        Return 51004
    End

    If @type = 'na'
    Begin
        Set @message = 'Containers of type "na" cannot be updated via the website; contact a DMS admin'
        Return 51006
    End

    ---------------------------------------------------
    -- Validate the researcher name
    ---------------------------------------------------

    Declare @matchCount int
    Declare @researcherUsername varchar(64)
    Declare @userID Int

    If @researcher In ('', 'na', 'none')
    Begin
        Set @message = 'Researcher must be a valid DMS user'
        Return 51011
    End

    exec auto_resolve_name_to_username @researcher, @matchCount output, @researcherUsername output, @userID output

    If @matchCount = 1
    Begin
        -- Single match found; update @researcher to be in the form 'Zink, Erika M (D3P704)'

        SELECT @researcher = Name_with_PRN
        FROM T_Users
        WHERE U_PRN = @researcherUsername

    End
    Else
    Begin
        -- Single match not found

        Set @message = 'Researcher must be a valid DMS user'

        If @matchCount = 0
            Set @message = @message + '; ' + @researcher + ' is an unknown person'
        Else
            Set @message = @message + '; ' + @researcher + ' is an ambiguous match to multiple people'

        Return 51011
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @containerID int = 0
    Declare @curLocationID int = 0
    Declare @curType varchar(32) = ''
    Declare @curStatus varchar(32) = ''
    --
    SELECT
        @containerID = ID,
        @curLocationID = Location_ID,
        @curType = Type,
        @curStatus = Status
    FROM  T_Material_Containers
    WHERE (Tag = @container)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error looking for existing entry for container ' + @container
        Return 51008
    End

    If @mode = 'add' and @containerID <> 0
    Begin
        Set @message = 'Cannot add container with same name as existing container: ' + @container
        Return 51010
    End

    If @mode In ('update', 'preview') and @containerID = 0
    Begin
        Set @message = 'No entry could be found in database for updating ' + @container
        Return 51012
    End

    ---------------------------------------------------
    -- Resolve input location name to ID and get limit
    ---------------------------------------------------

    Declare @locationID int = 0
    Declare @limit int = 0
    --
    SELECT
        @locationID = ID,
        @limit = Container_Limit
    FROM T_Material_Locations
    WHERE Tag = @location
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error resolving location ID for location ' + @location
        Return 51014
    End

    If @locationID = 0
    Begin
        Set @message = 'Invalid location: ' + @location + ' (for container ' + @container + ')'
        Return 51016
    End

    ---------------------------------------------------
    -- If moving a container, verify that there is room in destination location
    ---------------------------------------------------

    If @curLocationID <> @locationID
    Begin
        Declare @cnt int = 0
        --
        SELECT @cnt = COUNT(*)
        FROM T_Material_Containers
        WHERE Location_ID = @locationID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error getting container count for location ' + @location
            Return 51020
        End

        If @limit <= @cnt
        Begin
            Set @message = 'Destination location does not have room for another container (moving ' + @container + ' to ' + @location + ')'
            Return 51022
        End
    End

    ---------------------------------------------------
    -- Resolve current Location id to name
    ---------------------------------------------------

    Declare @curLocationName varchar(125) = ''
    --
    SELECT @curLocationName = Tag
    FROM T_Material_Locations
    WHERE ID = @curLocationID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error resolving name of current Location, ' + @curLocationName
        Return 510027
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin -- <add>
        -- future: accept '<next bag>' or '<next box> and generate container name

        INSERT INTO T_Material_Containers( Tag,
                                           [Type],
                                           [Comment],
                                           Barcode,
                                           Location_ID,
                                           [Status],
                                           Researcher )
        VALUES(@container, @type, @comment, @barcode, @locationID, @Status, @researcher)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed for container ' + @container
            Return 510028
        End

        -- Material movement logging
        --
        exec post_material_log_entry
             'Container Creation',
             @container,
             'na',
             @location,
             @callingUser,
             ''

    End -- </add>

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin -- <update>
        Set @myError = 0
        --
        UPDATE T_Material_Containers
        SET [Type] = @type,
            [Comment] = @comment,
            Barcode = @barcode,
            Location_ID = @locationID,
            [Status] = @Status,
            Researcher = @researcher
        WHERE Tag = @container
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed for container ' + @container
            Return 510029
        End

        -- Material movement logging
        --
        If @curLocationName <> @location
        Begin
            exec post_material_log_entry
                 'Container Move',
                 @container,
                 @curLocationName,
                 @location,
                 @callingUser,
                 ''
        End

    End -- </update>

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_material_container] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_material_container] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_material_container] TO [Limited_Table_Write] AS [dbo]
GO
