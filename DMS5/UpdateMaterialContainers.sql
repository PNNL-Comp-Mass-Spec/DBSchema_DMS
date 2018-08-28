/****** Object:  StoredProcedure [dbo].[UpdateMaterialContainers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[UpdateMaterialContainers]
/****************************************************
**
**  Desc: 
**      Makes changes for specified list of containers
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters: 
**
**  Auth:   grk
**  Date:   03/26/2008     - (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/17/2018 mem - Add mode 'unretire_container'
**                         - Do not allow updating containers of type 'na'
**          08/27/2018 mem - Rename the view Material Location list report view
**
*****************************************************/
(
    @mode varchar(32),                  -- 'move_container', 'retire_container', 'retire_container_and_contents', 'unretire_container'
    @containerList varchar(4096),       -- Container ID list
    @newValue varchar(128),
    @comment varchar(512),
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateMaterialContainers', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;
    
    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    
    Set @mode = IsNull(@mode, '')
    Set @containerList = IsNull(@containerList, '')
    Set @newValue= IsNull(@newValue, '')
    Set @comment= IsNull(@comment, '')
    Set @message = ''

    ---------------------------------------------------
    -- temporary table to hold containers
    ---------------------------------------------------

    Declare @material_container_list TABLE (
        ID int,
        iName varchar(128),
        iLocation varchar(64),
        iItemCount int,
        [Status] varchar(32),
        [Type] varchar(32)
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to create temporary table'
        return 51007
    end

    ---------------------------------------------------
    -- populate temporary table from container list
    ---------------------------------------------------
    
    INSERT INTO @material_container_list
        (ID, iName, iLocation, iItemCount, [Status], [Type])
    SELECT #ID,
           Container,
           Location,
           Items,
           [Status],
           [Type]
    FROM V_Material_Containers_List_Report
    WHERE #ID IN ( SELECT Item
                   FROM dbo.MakeTableFromList ( @containerList ) )

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error populating temporary table'
        return 51009
    end

    -- Remember how many containers are in the list
    --
    Declare @numContainers int = @myRowCount

    If @numContainers = 0
    Begin
        If CharIndex(',', @containerList) > 1
            set @message = 'Invalid Container IDs: ' + @containerList
        Else
            set @message = 'Invalid Container ID: ' + @containerList

        return 51010
    End

    If Exists (Select * From @material_container_list Where [Type] = 'na')
    Begin
        If CharIndex(',', @containerList) > 1
        Begin
            set @message = 'Containers of type "na" cannot be updated by the website; contact a DMS admin (see UpdateMaterialContainers)'
        End
        Else
        Begin
            Declare @containerName varchar(128) = Null

            Select @containerName = iName
            From @material_container_list

            set @message = 'Container "' + IsNull(@containerName, @containerList) + '" cannot be updated by the website; contact a DMS admin (see UpdateMaterialContainers)'
        End

        return 51011
    End

    ---------------------------------------------------
    -- resolve location to ID (according to mode)
    ---------------------------------------------------
    --
    Declare @location varchar(128) = 'None' -- the null location
    --
    Declare @locID int = 1  -- the null location
    --
    if @mode = 'move_container'
    begin -- <c>
        set @location = @newValue
        set @locID = 0
        --
        Declare @contCount int
        Declare @locLimit int
        Declare @locStatus varchar(64)
        --
        set @contCount = 0
        set @locLimit = 0
        set @locStatus = ''
        --
        SELECT 
            @locID = #ID, 
            @contCount = Containers,
            @locLimit = Limit, 
            @locStatus = [Status]
        FROM  V_Material_Location_List_Report
        WHERE Location = @location
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Could not resove location name "' + @location + '" to ID'
            return 51019
        end
        --
        if @locID = 0
        begin
            set @message = 'Destination location "' + @location + '" could not be found in database'
            return 51020
        end

        ---------------------------------------------------
        -- is location suitable?
        ---------------------------------------------------
        
        if @locStatus <> 'Active'
        begin
            set @message = 'Location "' + @location + '" is not in the "Active" state'
            return 51021
        end

        if @contCount + @numContainers > @locLimit
        begin
            set @message = 'The maximum container capacity (' + cast(@locLimit as varchar(12)) + ') of location "' + @location + '" would be exceeded by the move'
            return 51023
        end

    end -- </c>

    ---------------------------------------------------
    -- determine whether or not any containers have contents
    ---------------------------------------------------
    Declare @c int = 1
    --
    SELECT @c = count(*)
    FROM @material_container_list
    WHERE iItemCount > 0

    ---------------------------------------------------
    -- for 'plain' container retirement
    -- container must be empty
    ---------------------------------------------------
    --
    if @mode = 'retire_container' AND @c > 0
    begin
        set @message = 'All containers must be empty in order to retire them'
        return 51024
    end

    ---------------------------------------------------
    -- for 'contents' container retirement
    -- retire contents as well
    ---------------------------------------------------
    --
    -- arrange for containers and their contents to have common comment
    if @mode = 'retire_container_and_contents' AND @comment = ''
    Begin
        set @comment ='CR-' + convert(varchar, getdate(), 102) + '.' + convert(varchar, getdate(), 108)
    End

    -- retire the contents
    if @mode = 'retire_container_and_contents' AND @c > 0
    begin
        exec @myError = UpdateMaterialItems
                'retire_items',
                @containerList,
                'containers',
                '',
                @comment,
                @message output,
                @callingUser

        if @myError <> 0
            return @myError
    end

     if @mode = 'unretire_container'
     Begin
        -- Make sure the container(s) are all Inactive
        If Exists (Select * From @material_container_list Where [Status] <> 'Inactive')
        Begin
            If @numContainers = 1
                set @message = 'Container is already active; cannot unretire ' + @containerList
            Else
                set @message = 'All containers must be Inactive in order to unretire them: ' + @containerList
            return 51025
        End
     End

/*
select 'UpdateMaterialContainers' as Sproc, @mode as Mode, convert(char(22), @newValue) as Parameter, convert(char(12), @locID) as LocationID, @containerList as Containers
select * from @material_container_list
return 0
*/
    ---------------------------------------------------
    -- start transaction
    ---------------------------------------------------
    --
    Declare @transName varchar(32) = 'UpdateMaterialContainers'
    begin transaction @transName

    ---------------------------------------------------
    -- update containers to be at new location
    ---------------------------------------------------
    
    UPDATE T_Material_Containers
    SET 
        Location_ID = @locID,
        Status = CASE @mode 
                    WHEN 'retire_container'              THEN 'Inactive'
                    WHEN 'retire_container_and_contents' THEN 'Inactive' 
                    WHEN 'unretire_container'            THEN 'Active'
                    ELSE Status
                 END
    WHERE ID IN (SELECT ID FROM @material_container_list)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error updating location reference'
        return 51026
    end

    ---------------------------------------------------
    -- Set up appropriate label for log
    ---------------------------------------------------

    Declare @moveType varchar(128) = '??'

    if @mode = 'retire_container'
        set @moveType = 'Container Retirement'
    else
    if @mode = 'retire_container_and_contents'
        set @moveType = 'Container Retirement'
    else
    if @mode = 'unretire_container'
        set @moveType = 'Container Unretirement'
    else
    if @mode = 'move_container'
        set @moveType = 'Container Move'

    ---------------------------------------------------
    -- make log entries
    ---------------------------------------------------
    --
    INSERT INTO T_Material_Log (
        Type, 
        Item, 
        Initial_State, 
        Final_State, 
        User_PRN,
        Comment
    ) 
    SELECT 
        @moveType,
        iName,
        iLocation,
        @location,
        @callingUser,
        @comment
    FROM @material_container_list
    WHERE iLocation <> @location Or 
          @mode <> 'move_container'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        rollback transaction @transName
        set @message = 'Error making log entries'
        return 51027
    end
    
    commit transaction @transName

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialContainers] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMaterialContainers] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialContainers] TO [Limited_Table_Write] AS [dbo]
GO
