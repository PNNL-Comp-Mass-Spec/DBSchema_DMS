/****** Object:  StoredProcedure [dbo].[assure_material_containers_exist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[assure_material_containers_exist]
/****************************************************
**
**  Desc:
**      Examines the list of containers and/or locations in _containerList
**      For items that are locations, creates a new container by calling add_update_material_container
**      Returns a consolidated list of container names
**
**  Arguments:
**    @containerList        Input / Output: Comma separated list of locations and containers (can be a mix of both)
**    @comment              Comment
**    @type                 Container type: 'Box', 'Bag', or 'Wellplate'
**    @campaignName         Campaign name
**    @researcher           Researcher name; supports 'Zink, Erika M (D3P704)' or simply 'D3P704'
**    @mode                 Typically 'add' or 'create'
**                          However, if @mode is 'verify_only', will populate a temporary table with items in @containerList, then will exit the procedure without making any changes
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          04/27/2010 grk - Initial release
**          09/23/2011 grk - Accomodate researcher field in add_update_material_container
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/04/2023 mem - Use TOP 1 when retrieving the next item to process
**          11/19/2023 mem - Add procedure argument @campaignName
**
*****************************************************/
(
    @containerList varchar(1024) OUTPUT,
    @comment varchar(1024),
    @type varchar(32) = 'Box',
    @campaignName varchar(64),
    @researcher varchar(128),
    @mode varchar(12) = 'verify_only', -- or 'create'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''

    Declare @msg varchar(512) = ''

    Begin Try

        ---------------------------------------------------
        -- Get container list items into temp table
        ---------------------------------------------------
        --
        CREATE TABLE #TL (
            Container varchar(64) NULL,
            Item varchar(256),
            IsContainer TINYINT null,
            IsLocation TINYINT null
        )
        --
        INSERT INTO #TL (Item, IsContainer, IsLocation)
        SELECT Item, 0, 0 FROM dbo.make_table_from_list(@ContainerList)

        ---------------------------------------------------
        -- Mark list items as either container or location
        ---------------------------------------------------
        --
        UPDATE #TL
        SET IsContainer = 1,
            Container = Item
        FROM #TL
             INNER JOIN T_Material_Containers
               ON Item = Tag

        UPDATE #TL
        SET IsLocation = 1
        FROM #TL
             INNER JOIN T_Material_Locations
               ON Item = Tag


        ---------------------------------------------------
        -- Quick check of list
        ---------------------------------------------------

        Declare @s varchar(MAX) = ''

        SELECT @s = @s + CASE WHEN @s <> ''
                              THEN ', '
                              ELSE ''
                         END + Item
        FROM #TL
        WHERE IsLocation = 0 AND IsContainer = 0

        If @s <> ''
        Begin
            RAISERROR('Item(s) "%s" is/are not containers or locations', 11, 14, @s)
        End

        If @mode = 'verify_only'
            RETURN @myError

        ---------------------------------------------------
        -- Make new containers for locations
        ---------------------------------------------------
        --
        Declare @item varchar(64)
        Declare @Container varchar(128)
        --
        Declare @done tinyint = 0

        While @done = 0
        Begin
            SELECT TOP 1 @item = Item
            FROM #TL
            WHERE IsLocation > 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @done = 1
            End
            Else
            Begin

                Set @Container = '(generate name)'
                Exec @myError = add_update_material_container
                                    @container = @container output,
                                    @type = @Type,
                                    @location = @item,
                                    @comment = @Comment,
                                    @campaignName = @campaignName,
                                    @researcher = @Researcher,
                                    @mode = 'add',
                                    @message = @msg output,
                                    @callingUser = @callingUser
                --
                If @myError <> 0
                    RAISERROR('add_update_material_container: %s', 11, 21, @msg)


                UPDATE #TL
                SET Container = @Container, IsContainer = 1, IsLocation = 0
                WHERE Item = @item
            End
        End

        ---------------------------------------------------
        -- Make consolidated list of containers
        ---------------------------------------------------
        --
        Set @s = ''

        SELECT @s = @s + CASE WHEN @s <> ''
                              THEN ', '
                              ELSE ''
                         END + Container
        FROM #TL
        WHERE NOT Container IS NULL

        Set @ContainerList = @s

    End Try
    Begin Catch
        Exec format_error_message @message output, @myError output

        Exec post_log_entry 'Error', @message, 'assure_material_containers_exist'
    END Catch

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[assure_material_containers_exist] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[assure_material_containers_exist] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[assure_material_containers_exist] TO [Limited_Table_Write] AS [dbo]
GO
