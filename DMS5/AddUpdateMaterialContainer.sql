/****** Object:  StoredProcedure [dbo].[AddUpdateMaterialContainer] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateMaterialContainer]
/****************************************************
**
**  Desc: Adds new or edits an existing material container
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/20/2008 grk - Initial release
**          07/18/2008 grk - Added checking for location's container limit
**          11/25/2008 grk - Corrected udpdate not to check for room if location doesn't change
**          07/28/2011 grk - Added owner field
**          08/01/2011 grk - Always create new container if mode is "add"
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Validate inputs
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @Container varchar(128) output,
    @Type varchar(32),          -- Box, bag, or Wellplate
    @Location varchar(24),
    @Comment varchar(1024),
    @Barcode varchar(32),
    @Researcher VARCHAR(128),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output, 
    @callingUser varchar(128) = ''
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @Status varchar(32) = 'Active'

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'AddUpdateMaterialContainer', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Make sure the inputs are not null
    -- Additional validation occurs later
    ---------------------------------------------------

    Set @Container = LTrim(RTrim(IsNull(@Container, '')))
    Set @Type = LTrim(RTrim(IsNull(@Type, 'Box')))
    Set @Location = LTrim(RTrim(IsNull(@Location, '')))
    Set @Comment = LTrim(RTrim(IsNull(@Comment, '')))
    Set @Barcode = LTrim(RTrim(IsNull(@Barcode, '')))
    Set @Researcher = LTrim(RTrim(IsNull(@Researcher, '')))
    Set @mode = IsNull(@mode, '')

    ---------------------------------------------------
    -- optionally generate name
    ---------------------------------------------------

    if @Container = '(generate name)' OR @mode = 'add'
    begin
        Declare @tmp int
        --
        SELECT @tmp = MAX(ID) + 1
        FROM  T_Material_Containers
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error trying to auto-generate the container name'
            return 51000
        end
        
        set @Container = 'MC-' + cast(@tmp as varchar(12))
    end

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
        
    If Len(@Container) = 0
    Begin
        set @message = 'Container name cannot be empty'
        return 51002
    End

    If @Container In ('na', 'Staging', '-80_Staging', 'Met_Staging')
    Begin
        set @message = 'The "' + @Container + '" container cannot be updated via the website; contact a DMS admin (see AddUpdateMaterialContainer)'
        return 51003
    End

    If @mode = 'add' And Not @Type In ('Box', 'Bag', 'Wellplate')
    Begin
        Set @Type = 'Box'
    End
    
    If Not @Type In ('Box', 'Bag', 'Wellplate')
    Begin
        set @message = 'Container type must be Box, Bag, or Wellplate'
        return 51004
    End
    
    If @Type = 'na'
    Begin
        set @message = 'Containers of type "na" cannot be updated via the website; contact a DMS admin'
        return 51006
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
    WHERE (Tag = @Container)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for existing entry'
        return 51008
    end

    if @mode = 'add' and @containerID <> 0
    begin
        set @message = 'Cannot add container with same name as existing container: ' + @Container
        return 51010
    end

    if @mode = 'update' and @containerID = 0
    begin
        set @message = 'No entry could be found in database for updating ' + @Container
        return 51012
    end

    ---------------------------------------------------
    -- Resolve input location name to ID and get limit
    ---------------------------------------------------

    Declare @LocationID int = 0
    Declare @limit int = 0
    --
    SELECT 
        @LocationID = ID, 
        @limit = Container_Limit
    FROM T_Material_Locations
    WHERE Tag = @Location    
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error resolving location ID'
        return 51014
    end

    If @LocationID = 0
    Begin
        set @message = 'Invalid location: ' + @Location
        return 51016
    End

    ---------------------------------------------------
    -- If moving a container, verify that there is room in destination location
    ---------------------------------------------------

    if @curLocationID <> @LocationID
    begin --<n>
        Declare @cnt int = 0
        --
        SELECT @cnt = COUNT(*)
        FROM T_Material_Containers
        WHERE Location_ID = @LocationID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error getting container count'
            return 51020
        end
        if @limit <= @cnt
        begin
            set @message = 'Destination location does not have room for another container'
            return 51022
        end
    end --<n>
    
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
    if @myError <> 0
    begin
        set @message = 'Error resolving name of current Location'
        return 510027
    end
    
    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin -- <add>
        -- future: accept '<next bag>' or '<next box> and generate container name
            
        INSERT INTO T_Material_Containers
        (
            Tag ,
            Type ,
            Comment ,
            Barcode ,
            Location_ID ,
            Status ,
            Researcher
        ) VALUES (
            @Container ,
            @Type ,
            @Comment ,
            @Barcode ,
            @LocationID ,
            @Status ,
            @Researcher
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Insert operation failed'
            return 510028
        end

        --  material movement logging
        --    
        exec PostMaterialLogEntry
            'Container Creation',
            @Container,
            'na',
            @Location,
            @callingUser,
            ''

    end -- </add>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update' 
    begin -- <update>
        set @myError = 0
        --
        UPDATE  T_Material_Containers
        SET     Type = @Type ,
                Comment = @Comment ,
                Barcode = @Barcode ,
                Location_ID = @LocationID ,
                Status = @Status ,
                Researcher = @Researcher
        WHERE   ( Tag = @Container )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Update operation failed: "' + @Container + '"'
            return 510029
        end

        --  material movement logging
        --    
        if @curLocationName <> @Location
        begin
            exec PostMaterialLogEntry
                'Container Move',
                @Container,
                @curLocationName,
                @Location,
                @callingUser,
                ''
        end

    end -- </update>

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateMaterialContainer] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateMaterialContainer] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateMaterialContainer] TO [Limited_Table_Write] AS [dbo]
GO
