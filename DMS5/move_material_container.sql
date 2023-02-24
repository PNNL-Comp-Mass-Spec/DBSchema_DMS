/****** Object:  StoredProcedure [dbo].[move_material_container] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[move_material_container]
/****************************************************
**
**  Desc:   Moves a container to a new location
**
**          Optionally provide the old location to assure that
**          the container is only moved if the old location matches
**          what is currently defined in DMS
**
**          Optionally also change the researcher associated with the container
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/19/2018 mem - Initial release
**          12/20/2018 mem - Include container name in warnings
**          03/02/2022 mem - Compare current container location to @newLocation before validating @oldLocation
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @container varchar(128),
    @oldLocation varchar(24) = '',
    @newLocation varchar(24) = '',
    @newResearcher varchar(128) = '',       -- Supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
    @infoOnly tinyint = 1,
    @message varchar(512) = '' output
)
AS
    Set NoCount On

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @callingUser varchar(24) = suser_sname()
    Declare @slashLoc int = CharIndex('\', @callingUser)

    If @slashLoc > 0
    Begin
        Set @callingUser = Substring(@callingUser, @slashLoc + 1, 100)
    End

    Set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'move_material_container', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Make sure the inputs are not null
    -- Additional validation occurs later
    ---------------------------------------------------

    Set @container = LTrim(RTrim(IsNull(@container, '')))
    Set @oldLocation = LTrim(RTrim(IsNull(@oldLocation, '')))
    Set @newLocation = LTrim(RTrim(IsNull(@newLocation, '')))
    Set @newResearcher = LTrim(RTrim(IsNull(@newResearcher, '')))
    Set @infoOnly = IsNull(@infoOnly, 1)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If Len(@container) = 0
    Begin
        set @message = 'Container name cannot be empty'
        Select @message As Warning
        return 51002
    End

    If Len(@newLocation) = 0
    Begin
        set @message = 'NewLocation cannot be empty'
        Select @message As Warning
        return 51003
    End

    ---------------------------------------------------
    -- Lookup the container's information
    ---------------------------------------------------

    Declare @containerID int = 0
    Declare @curLocation varchar(24) = ''
    Declare @containerType varchar(32) = ''
    Declare @containerComment varchar(1024)
    Declare @barcode varchar(32)
    Declare @researcher varchar(128)
    Declare @mode varchar(24)
    --
    SELECT @containerID = MC.ID,
           @curLocation = ML.Tag,
           @containerType = MC.[Type],
           @containerComment = MC.Comment,
           @barcode = MC.Barcode,
           @researcher = MC.Researcher
    FROM T_Material_Containers AS MC
         INNER JOIN T_Material_Locations AS ML
           ON MC.Location_ID = ML.ID
    WHERE MC.Tag = @container
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for existing entry for ' + @container
        Select @message As Warning
        return 51008
    end

    If @myRowCount <> 1
    Begin
        Set @message = 'Container not found: ' + @container
        Select @message As Warning
        return 51009
    End

    If @newLocation = @curLocation And (Len(@newResearcher) = 0 Or @researcher = @newResearcher)
    Begin
        Set @message = 'Container is already at ' + @newLocation + ' (and not changing the researcher name): ' + @container
        Select @message As Warning
        Return 51011
    End

    If Len(@oldLocation) > 0 And @oldLocation <> @curLocation
    Begin
        Set @message = 'Current container location does not match the expected location: ' + @curLocation + ' vs. expected ' + @oldLocation + ' for ' + @container
        Select @message As Warning
        Return 51010
    End

    If Len(@newResearcher) > 0
    Begin
        Set @researcher = @newResearcher
    End

    If @infoOnly <> 0
    Begin
        Set @mode= 'Preview'
    End
    Else
    Begin
        Set @mode = 'Update'
    End

    Exec @myError = add_update_material_container @container = @container
                                              ,@type = @containerType
                                              ,@location = @newLocation
                                              ,@comment = @containerComment
                                              ,@barcode = @barcode
                                              ,@researcher = @researcher
                                              ,@mode = @mode
                                              ,@message = @message output
                                              ,@callingUser = @callingUser

    If @myError <> 0
    Begin
        Select @message As Warning
    End
    Else
    Begin
        If @infoOnly = 0
            Set @message = 'Moved container ' + @container + ' from ' + @curLocation + ' to ' + @newLocation
        Else
            Set @message = 'Container ' + @container + ' can be moved from ' + @curLocation + ' to ' + @newLocation

        Select @message As Comment
    End

    return @myError

GO
