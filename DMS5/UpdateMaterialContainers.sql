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
**          06/21/2022 mem - Use new column name Container_Limit in view V_Material_Location_List_Report
**          07/07/2022 mem - Include container name in "container not empty" message
**          10/22/2022 mem - Use an underscore to separate date and time in the auto-generated comment
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
    If @myError <> 0
    Begin
        Set @message = 'Failed to create temporary table'
        return 51007
    End

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
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary table'
        return 51009
    End

    -- Remember how many containers are in the list
    --
    Declare @numContainers int = @myRowCount

    If @numContainers = 0
    Begin
        If CharIndex(',', @containerList) > 1
            Set @message = 'Invalid Container IDs: ' + @containerList
        Else
            Set @message = 'Invalid Container ID: ' + @containerList

        return 51010
    End

    If Exists (Select * From @material_container_list Where [Type] = 'na')
    Begin
        If CharIndex(',', @containerList) > 1
        Begin
            Set @message = 'Containers of type "na" cannot be updated by the website; contact a DMS admin (see UpdateMaterialContainers)'
        End
        Else
        Begin
            Declare @containerName varchar(128) = Null

            Select @containerName = iName
            From @material_container_list

            Set @message = 'Container "' + IsNull(@containerName, @containerList) + '" cannot be updated by the website; contact a DMS admin (see UpdateMaterialContainers)'
        End

        return 51011
    End

    ---------------------------------------------------
    -- Resolve location to ID (according to mode)
    ---------------------------------------------------
    --
    Declare @location varchar(128) = 'None' -- the null location
    --
    Declare @locID int = 1  -- the null location
    --
    If @mode = 'move_container'
    Begin -- <c>
        Set @location = @newValue
        Set @locID = 0
        --
        Declare @contCount int
        Declare @locLimit int
        Declare @locStatus varchar(64)
        --
        Set @contCount = 0
        Set @locLimit = 0
        Set @locStatus = ''
        --
        SELECT
            @locID = #ID,
            @contCount = Containers,
            @locLimit = Container_Limit,
            @locStatus = [Status]
        FROM  V_Material_Location_List_Report
        WHERE Location = @location
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Could not resove location name "' + @location + '" to ID'
            return 51019
        End
        --
        If @locID = 0
        Begin
            Set @message = 'Destination location "' + @location + '" could not be found in database'
            return 51020
        End

        ---------------------------------------------------
        -- is location suitable?
        ---------------------------------------------------

        If @locStatus <> 'Active'
        Begin
            Set @message = 'Location "' + @location + '" is not in the "Active" state'
            return 51021
        End

        If @contCount + @numContainers > @locLimit
        Begin
            Set @message = 'The maximum container capacity (' + cast(@locLimit as varchar(12)) + ') of location "' + @location + '" would be exceeded by the move'
            return 51023
        End

    End -- </c>

    ---------------------------------------------------
    -- determine whether or not any containers have contents
    ---------------------------------------------------
    Declare @nonEmptyContainerCount int = 1
    Declare @nonEmptyContainers Varchar(255)
    --
    SELECT @nonEmptyContainerCount = count(*)
    FROM @material_container_list
    WHERE iItemCount > 0

    ---------------------------------------------------
    -- for 'plain' container retirement
    -- container must be empty
    ---------------------------------------------------
    --
    If @mode = 'retire_container' AND @nonEmptyContainerCount > 0
    Begin
        If @numContainers = 1
        Begin
            Set @message = 'Container ' + @containerList + ' is not empty; cannot retire it'
        End
        Else
        Begin
            Set @nonEmptyContainers = Null

            Select @nonEmptyContainers = Coalesce(@nonEmptyContainers + ', ' + iName, iName)
            From @material_container_list
            Order By iName

            Set @message = 'All containers must be empty in order to retire them; see ' + @nonEmptyContainers
        End
        
        return 51024
    End

    ---------------------------------------------------
    -- for 'contents' container retirement
    -- retire contents as well
    ---------------------------------------------------
    
    -- Arrange for containers and their contents to have common comment
    -- Example comment: CR-2022.08.11_14:23:11

    If @mode = 'retire_container_and_contents' AND @comment = ''
    Begin
        Set @comment ='CR-' + convert(varchar, getdate(), 102) + '_' + convert(varchar, getdate(), 108)
    End

    -- retire the contents
    If @mode = 'retire_container_and_contents' AND @nonEmptyContainerCount > 0
    Begin
        exec @myError = UpdateMaterialItems
                'retire_items',
                @containerList,
                'containers',
                '',
                @comment,
                @message output,
                @callingUser

        If @myError <> 0
            return @myError
    End

     If @mode = 'unretire_container'
     Begin
        -- Make sure the container(s) are all Inactive
        If Exists (Select * From @material_container_list Where [Status] <> 'Inactive')
        Begin
            If @numContainers = 1
                Set @message = 'Container is already active; cannot unretire ' + @containerList
            Else
                Set @message = 'All containers must be Inactive in order to unretire them: ' + @containerList
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
    Begin transaction @transName

    ---------------------------------------------------
    -- update containers to be at new location
    ---------------------------------------------------

    UPDATE T_Material_Containers
    Set
        Location_ID = @locID,
        Status = CASE @mode
                    WHEN 'retire_container'              THEN 'Inactive'
                    WHEN 'retire_container_and_contents' THEN 'Inactive'
                    WHEN 'unretire_container'            THEN 'Active'
                    ELSE Status
                 End
    WHERE ID IN (SELECT ID FROM @material_container_list)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error updating location reference'
        return 51026
    End

    ---------------------------------------------------
    -- Set up appropriate label for log
    ---------------------------------------------------

    Declare @moveType varchar(128) = '??'

    If @mode = 'retire_container'
        Set @moveType = 'Container Retirement'
    else
    If @mode = 'retire_container_and_contents'
        Set @moveType = 'Container Retirement'
    else
    If @mode = 'unretire_container'
        Set @moveType = 'Container Unretirement'
    else
    If @mode = 'move_container'
        Set @moveType = 'Container Move'

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
    If @myError <> 0
    Begin
        rollback transaction @transName
        Set @message = 'Error making log entries'
        return 51027
    End

    commit transaction @transName

    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialContainers] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMaterialContainers] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialContainers] TO [Limited_Table_Write] AS [dbo]
GO
