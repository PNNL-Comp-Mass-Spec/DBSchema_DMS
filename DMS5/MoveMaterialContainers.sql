/****** Object:  StoredProcedure [dbo].[MoveMaterialContainers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[MoveMaterialContainers]
/****************************************************
**
**  Desc: 
**      Moves containers from one location to another
**      Allows for moving between freezers, shelves, and racks, but requires that Row and Col remain unchanged
**      Created in August 2016 to migrate samples from old freezer 1206A to new freezer 1206A, which  has more shelves but fewer racks
**
**  Auth:   mem
**  Date:   08/03/2016
**          08/27/2018 mem - Rename the view Material Location list report view
**    
*****************************************************/
(
    @freezerTagOld varchar(24),
    @ShelfOld int,
    @RackOld int,
    @freezerTagNew varchar(24),
    @ShelfNew int,
    @RackNew int,
    @infoOnly tinyint = 1,
    @message varchar(255) = '' output,
    @callingUser varchar(128) = ''
)
As
    Declare @myRowCount int = 0
    Declare @myError int = 0

    ---------------------------------------------------
    -- Validate the Inputs
    ---------------------------------------------------
    
    Set @freezerTagOld = IsNull(@freezerTagOld, '')
    Set @ShelfOld = IsNull(@ShelfOld, -1)
    Set @RackOld = IsNull(@RackOld, -1)
    
    Set @freezerTagNew = IsNull(@freezerTagNew, '')
    Set @ShelfNew = IsNull(@ShelfNew, -1)
    Set @RackNew = IsNull(@RackNew, -1)
    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @message = ''
    Set @callingUser = IsNull(@callingUser, '')
    
    If @freezerTagOld = ''
    Begin
        Set @message = '@freezerTagOld cannot be empty'
        Goto Done
    End

    If @freezerTagNew = ''
    Begin
        Set @message = '@freezerTagNew cannot be empty'
        Goto Done
    End
    
    If @ShelfOld <= 0 or @RackOld <= 0
    Begin
        Set @message = '@ShelfOld and @RackOld must be positive integers'
        Goto Done
    End
    
    If @ShelfNew <= 0 or @RackNew <= 0
    Begin
        Set @message = '@ShelfNew and @RackNew must be positive integers'
        Goto Done
    End
    
    If @callingUser = ''
    Begin
        Set @callingUser = Suser_Sname()
    End

    ---------------------------------------------------
    -- Create some temporary tables
    ---------------------------------------------------
    --        
    CREATE TABLE #Tmp_ContainersToProcess (
        Entry_ID     int IDENTITY ( 1, 1 ) NOT NULL,
        MC_ID        int NOT NULL,
        Container    varchar(128) NOT NULL,
        [Type]       varchar(32) NOT NULL,
        Location_ID  int NOT NULL,
        Location_Tag varchar(224) NOT NULL,
        Shelf        varchar(50) NOT NULL,
        Rack         varchar(50) NOT NULL,
        Row          varchar(50) NOT NULL,
        Col          varchar(50) NOT NULL
    )

    CREATE TABLE #Tmp_Move_Status (
        Container_ID     int NOT NULL,
        Container        varchar(128) NOT NULL,
        [Type]           varchar(32) NOT NULL,
        Location_Old     varchar(225) NOT NULL,
        Location_Current varchar(225) NOT NULL,
        Location_New     varchar(225) NOT NULL,
        LocationIDNew    int NOT NULL,
        Status           varchar(32) NULL
    )


    ---------------------------------------------------
    -- Populate the table
    ---------------------------------------------------
    --        
    INSERT INTO #Tmp_ContainersToProcess (MC_ID, Container, [Type], Location_ID, Location_Tag, Shelf, Rack, Row, Col )
    SELECT MC.ID AS MC_ID,
           MC.Tag AS Container,
           MC.[Type],
           MC.Location_ID,
           ML.Tag AS Location_Tag,
           ML.Shelf,
           ML.Rack,
           ML.Row,
           ML.Col
    FROM T_Material_Containers MC
         INNER JOIN T_Material_Locations ML
           ON MC.Location_ID = ML.ID
    WHERE (ML.Freezer_Tag = @freezerTagOld) AND
          ML.Shelf = CAST(@ShelfOld AS varchar(20)) AND
          ML.Rack = CAST(@RackOld AS varchar(20))
    ORDER BY location_tag
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Not Exists (SELECT * FROM #Tmp_ContainersToProcess)
    Begin
        Set @message = 'No containers found in freezer ' + @freezerTagOld + ', shelf ' + CAST(@ShelfOld AS varchar(20)) + ', rack ' + CAST(@RackOld AS varchar(20))
        Goto Done
    End

    ---------------------------------------------------
    -- Show the matching containers
    ---------------------------------------------------
    --    
    SELECT *
    FROM #Tmp_ContainersToProcess

    ---------------------------------------------------
    -- Step through the containers and update their location
    ---------------------------------------------------
    --    
    Declare @EntryID int = 0
    Declare @ContainerID int
    Declare @ContainerName varchar(128)
    Declare @LocationIDOld int
    Declare @LocationTagOld varchar(128)
    Declare @ShelfOldText varchar(50)
    Declare @RackOldText varchar(50)
    Declare @Row varchar(50)
    Declare @Col varchar(50)

    Declare @LocationTagNew varchar(128)
    Declare @LocationIDNew int
    Declare @numContainers int

    Declare @contCount int
    Declare @locLimit int
    Declare @locStatus varchar(64)
    
    Declare @moveStatus varchar(32)
    Declare @transName varchar(32) = 'UpdateMaterialContainers'

    Begin transaction @transName

    Declare @continue tinyint = 1
    While @continue = 1
    Begin -- <a>
        SELECT TOP 1 @EntryID = Entry_ID,
                     @ContainerID = MC_ID,
                     @ContainerName = Container,
                     @LocationIDOld = Location_ID,
                     @LocationTagOld = Location_Tag,
                     @ShelfOldText = Shelf,
                     @RackOldText = Rack,
                     @Row = Row,
                     @Col = Col
        FROM #Tmp_ContainersToProcess
        WHERE Entry_ID > @EntryID
        ORDER BY Entry_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount= 0
        Begin
            SET @continue = 0
        End
        Else
        Begin -- <b>
            SET @LocationTagNew = @freezerTagNew + '.' + CAST(@ShelfNew as varchar(20)) + '.' + CAST(@RackNew as varchar(20)) + '.' + @Row + '.' + @Col
            SET @numContainers = 1

            SELECT 
                @LocationIDNew = #ID, 
                @contCount = Containers,
                @locLimit = Limit, 
                @locStatus = Status
            FROM  V_Material_Location_List_Report
            WHERE Location = @LocationTagNew
            --
            If @LocationIDNew = 0
            Begin
                set @message = 'Destination location "' + @LocationTagNew + '" could not be found in database'
                rollback transaction @transName
                GOTO Done
            End

            ---------------------------------------------------
            -- is location suitable?
            ---------------------------------------------------
            
            If @locStatus <> 'Active'
            Begin
                set @message = 'Location "' + @LocationTagNew + '" is not in the "Active" state'
                rollback transaction @transName
                GOTO Done
            End

            If @contCount + @numContainers > @locLimit
            Begin
                set @message = 'The maximum container capacity (' + cast(@locLimit as varchar(12)) + ') of location "' + @LocationTagNew + '" would be exceeded by the move'
                rollback transaction @transName
                GOTO Done
            End
        
            If @infoOnly <> 0
            Begin
                Set @moveStatus = 'Preview'
            End
            Else
            Begin -- <c>
            
                Set @moveStatus = 'Moved'
            
                ---------------------------------------------------
                -- Update container to be at new location
                ---------------------------------------------------

                UPDATE T_Material_Containers
                SET Location_ID = @LocationIDNew
                WHERE ID = @ContainerID
                   --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    rollback transaction @transName
                    set @message = 'Error updating location reference'
                    GOTO Done
                End

                INSERT INTO T_Material_Log (
                    [Type], 
                    Item, 
                    Initial_State, 
                    Final_State, 
                    User_PRN,
                    Comment
                ) 
                VALUES(
                    'move_container',
                    @ContainerName,
                    @LocationTagOld,
                    @LocationTagNew,
                    'pnl\d3l243',
                    'Rearrange after replacing freezer 1206A'
                )
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                If @myError <> 0
                Begin
                    rollback transaction @transName
                    set @message = 'Error making log entries'
                    GOTO Done
                End

            End -- </c>
            
            INSERT INTO #Tmp_Move_Status (Container_ID, Container, [Type], Location_Old, Location_Current, Location_New, LocationIDNew, Status)
            SELECT     #ID AS Container_ID,
                    Container,
                    [Type],
                    @LocationTagOld AS Location_Old,
                    Location AS Location_Current,
                    @LocationTagNew AS Location_New,
                    @LocationIDNew AS LocationIDNew,
                    @moveStatus
            FROM V_Material_Containers_List_Report
            WHERE #ID = @ContainerID


        End -- </b>
    End -- </a>

    commit transaction @transName


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    SELECT * FROM #Tmp_Move_Status

Done:

    If @message <> ''
    Begin
        Select @message as Message
    End

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[MoveMaterialContainers] TO [DDL_Viewer] AS [dbo]
GO
