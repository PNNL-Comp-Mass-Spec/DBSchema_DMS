/****** Object:  StoredProcedure [dbo].[add_new_freezer] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_new_freezer]
/****************************************************
**
**  Desc: Adds a new Freezer to T_Material_Locations
**
**        You must first manually add a row to T_Material_Freezers
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   04/22/2015 mem - Initial version
**          03/31/2016 mem - Switch to using Freezer tags (and remove parameter @NewTagBase)
**          11/13/2017 mem - Skip computed column Tag when copying data
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @sourceFreezerTag varchar(24) = '2240B',
    @newFreezerTag varchar(24) = '1215A',
    @infoOnly tinyint = 1,
    @message varchar(512) = '' output
)
AS
    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @sourceFreezerTag = IsNull(@sourceFreezerTag, '')
    Set @newFreezerTag = IsNull(@newFreezerTag, '')
    set @infoOnly = IsNull(@infoOnly, 1)
    set @message = ''

    If @sourceFreezerTag = ''
    Begin
        set @message = 'Source freezer tag is empty'
        RAISERROR (@message, 10, 1)
        return 51002
    End

    If @newFreezerTag = ''
    Begin
        set @message = 'New freezer tag is empty'
        RAISERROR (@message, 10, 1)
        return 51000
    End

    If Len(@newFreezerTag) < 4
    Begin
        set @message = '@newFreezerTag should be at least 4 characters long, e.g. 1213A'
        RAISERROR (@message, 10, 1)
        return 51001
    End

    ---------------------------------------------------
    -- Check for existing data
    ---------------------------------------------------

    If Exists (SELECT * FROM T_Material_Locations WHERE Freezer_Tag = @newFreezerTag)
    Begin
        set @message = 'Cannot add ''' + @newFreezerTag + ''' because it already exists in T_Material_Locations'
        RAISERROR (@message, 10, 1)
        return 51004
    End

    If Not Exists (SELECT * FROM T_Material_Locations WHERE Freezer_Tag = @sourceFreezerTag)
    Begin
        set @message = 'Source freezer tag not found in T_Material_Locations: ' + @sourceFreezerTag
        RAISERROR (@message, 10, 1)
        return 51004
    End

    If Not Exists (SELECT * FROM T_Material_Freezers WHERE Freezer_Tag = @newFreezerTag)
    Begin
        set @message = 'New freezer tag not found in T_Material_Freezers: ' + @newFreezerTag
        RAISERROR (@message, 10, 1)
        return 51004
    End

    ---------------------------------------------------
    -- Cache the new rows in a temporary table
    ---------------------------------------------------
    --
    CREATE TABLE #Tmp_T_Material_Locations (
        ID              int IDENTITY ( 1000, 1 ) NOT NULL,
        Freezer_Tag     varchar(24) NULL,
        Shelf           varchar(50) NOT NULL,
        Rack            varchar(50) NOT NULL,
        Row             varchar(50) NOT NULL,
        Col             varchar(50) NOT NULL,
        Status          varchar(32) NOT NULL,
        Barcode         varchar(50) NULL,
        Comment         varchar(512) NULL,
        Container_Limit int NOT NULL
    )

    INSERT INTO #Tmp_T_Material_Locations( Freezer_Tag,
                                           Shelf,
                                           Rack,
                                           Row,
                                           Col,
                                           Status,
                                           Barcode,
                                           [Comment],
                                           Container_Limit )
    SELECT @newFreezerTag AS New_Freezer_Tag,
           Shelf,
           Rack,
           Row,
           Col,
           Status,
           Barcode,
           [Comment],
           Container_Limit
    FROM T_Material_Locations
    WHERE (Freezer_Tag = @sourceFreezerTag) AND
          (NOT (ID IN ( SELECT ID
                        FROM T_Material_Locations
                        WHERE (Freezer_Tag = @sourceFreezerTag) AND
                              (Status = 'inactive') AND
                            (Col = 'na') )))
    ORDER BY Shelf, Rack, Row, Col

    ---------------------------------------------------
    -- Preview or store the rows
    ---------------------------------------------------
    --
    If @infoOnly <> 0
    Begin
        SELECT *
        FROM #Tmp_T_Material_Locations
        ORDER BY Shelf, Rack, Row, Col
    End
    Else
    Begin
        INSERT INTO T_Material_Locations( Freezer_Tag,
                                          Shelf,
                                          Rack,
                                          Row,
                                          Col,
                                          Status,
                                          Barcode,
                                          [Comment],
                                          Container_Limit )
        SELECT Freezer_Tag,
               Shelf,
               Rack,
               Row,
               Col,
               Status,
               Barcode,
               [Comment],
               Container_Limit
        FROM #Tmp_T_Material_Locations
        ORDER BY Shelf, Rack, Row, Col
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @message = 'Error adding rows to T_Material_Locations for freezer_tag ' + @sourceFreezerTag
            RAISERROR (@message, 10, 1)
            return 51006
        end

        Set @message = 'Added ' + Cast(@myRowCount as varchar(12)) + ' rows to T_Material_Locations by copying freezer_tag ' + @sourceFreezerTag

        Exec post_log_entry 'Normal', @message, 'add_new_freezer'
    End

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------
    --

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[add_new_freezer] TO [DDL_Viewer] AS [dbo]
GO
