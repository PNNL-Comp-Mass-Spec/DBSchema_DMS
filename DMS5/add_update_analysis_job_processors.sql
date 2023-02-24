/****** Object:  StoredProcedure [dbo].[add_update_analysis_job_processors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_analysis_job_processors]
/****************************************************
**
**  Desc: Adds new or edits existing T_Analysis_Job_Processors
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
** Auth:    grk
** Date:    02/15/2007 (ticket 389)
**          02/23/2007 grk - added @AnalysisToolsList stuff
**          03/15/2007 mem - Tweaked invalid tool name error message
**          02/13/2008 mem - Now assuring that @AnalysisToolsList results in a non-redundant list of analysis tool names (Ticket #643)
**          03/25/2008 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @id int output,
    @state char(1),
    @processorName varchar(64),
    @machine varchar(64),
    @notes varchar(512),
    @analysisToolsList varchar(1024),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_analysis_job_processors', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- Create temporary table to hold list of analysis tools
    ---------------------------------------------------

    CREATE TABLE #TD (
        ToolName varchar(128),
        ToolID int null
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Failed to create temporary table'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    ---------------------------------------------------
    -- Populate table from dataset list
    ---------------------------------------------------
    --
    INSERT INTO #TD
        (ToolName)
    SELECT
        DISTINCT Item
    FROM
        make_table_from_list(@AnalysisToolsList)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error populating temporary table'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    ---------------------------------------------------
    -- Get tool ID for each tool in temp table
    ---------------------------------------------------
    --
    UPDATE T
    SET T.ToolID = AJT_toolID
    FROM #TD T INNER JOIN T_Analysis_Tool ON T.ToolName = AJT_toolName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating temporary table'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    ---------------------------------------------------
    -- Any invalid tool names?
    ---------------------------------------------------
    --
    declare @tmp int
    set @tmp = -1
    --
    SELECT @tmp = count(*)
    FROM #TD
    WHERE ToolID is null
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking for invalid tool names'
        RAISERROR (@message, 10, 1)
        return 51007
    end
    --
    if @tmp <> 0
    begin
        SELECT TOP 1 @message = ToolName
        FROM #TD
        WHERE ToolID is null

        set @message = 'Invalid tool name: ' + IsNull(@message, '??')
        RAISERROR (@message, 10, 1)
        return 51008
    end

    ---------------------------------------------------
    -- Is entry already in database? (only applies to updates)
    ---------------------------------------------------

    if @mode = 'update'
    begin
        -- cannot update a non-existent entry
        --
        set @tmp = 0
        --
        SELECT @tmp = ID
        FROM  T_Analysis_Job_Processors
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 OR @tmp = 0
        begin
            set @message = 'Cannot update processor ID ' + Convert(varchar(12), @ID) + '; existing entry not found in the database'
            RAISERROR (@message, 10, 1)
            return 51007
        end
    end

    ---------------------------------------------------
    -- set up transaction name
    ---------------------------------------------------
    declare @transName varchar(32)
    set @transName = 'add_update_analysis_job_processors'

    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    if @Mode = 'add'
    begin
        ---------------------------------------------------
        -- start transaction
        --
        begin transaction @transName

        INSERT INTO T_Analysis_Job_Processors (
            State,
            Processor_Name,
            Machine,
            Notes
        ) VALUES (
            @State,
            @ProcessorName,
            @Machine,
            @Notes
        )
        /**/
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            return 51007
        end

        -- return ID of newly created entry
        --
        set @ID = SCOPE_IDENTITY()

        -- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processors
        If Len(@callingUser) > 0
            Exec alter_entered_by_user 'T_Analysis_Job_Processors', 'ID', @ID, @CallingUser, @EntryDateColumnName='Last_Affected'

    end -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    if @Mode = 'update'
    begin
        set @myError = 0

        ---------------------------------------------------
        -- start transaction
        --
        begin transaction @transName

        UPDATE T_Analysis_Job_Processors
        SET
            State = @State,
            Processor_Name = @ProcessorName,
            Machine = @Machine,
            Notes = @Notes
        WHERE (ID = @ID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Update operation failed: "' + @ID + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        end

        -- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processors
        If Len(@callingUser) > 0
            Exec alter_entered_by_user 'T_Analysis_Job_Processors', 'ID', @ID, @CallingUser, @EntryDateColumnName='Last_Affected'

    end -- update mode

    ---------------------------------------------------
    -- action for both modes
    ---------------------------------------------------

    if @Mode = 'add' or @Mode = 'update'
    begin
        ---------------------------------------------------
        -- remove any references to tools that are not in the list
        --
        DELETE FROM T_Analysis_Job_Processor_Tools
        WHERE Processor_ID = @ID AND Tool_ID NOT IN (SELECT ToolID FROM #TD)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Remove tool reference operation failed'
            RAISERROR (@message, 10, 1)
            return 51004
        end

        ---------------------------------------------------
        -- add references to tools that are in the list, but not in the table
        --
        INSERT INTO T_Analysis_Job_Processor_Tools
            (Tool_ID, Processor_ID)
        SELECT  ToolID, @ID
        FROM #TD
        WHERE NOT ToolID IN
            (
                SELECT Tool_ID
                FROM T_Analysis_Job_Processor_Tools
                WHERE (Processor_ID = @ID)
            )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            rollback transaction @transName
            set @message = 'Add tool reference operation failed'
            RAISERROR (@message, 10, 1)
            return 51004
        end

        -- If @callingUser is defined, then update Entered_By in T_Analysis_Job_Processor_Tools
        If Len(@callingUser) > 0
            Exec alter_entered_by_user 'T_Analysis_Job_Processor_Tools', 'Processor_ID', @ID, @CallingUser

        commit transaction @transName
    end -- add or update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_analysis_job_processors] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job_processors] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_analysis_job_processors] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_analysis_job_processors] TO [Limited_Table_Write] AS [dbo]
GO
