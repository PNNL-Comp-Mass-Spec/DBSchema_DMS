/****** Object:  StoredProcedure [dbo].[add_update_manager_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_manager_params]
/****************************************************
**
**  Desc:
**  Adds new or updates existing manager control param values in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   08/20/2007
**          04/16/2009 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**          04/17/2015 mem - Now ignoring parameters that are blank
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @targetEntityName varchar(128) = '',        -- Manager name
    @itemNameList varchar(4000) = '',           -- Parameter name list (param names separated by !)
    @itemValueList varchar(3000) = '',          -- Parameter value list (param values separated by !)
    @mode varchar(12) = 'add',                  -- Not used in this procedure
    @message varchar(512) = '' output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @callingUser = IsNull(@callingUser, '')

    ---------------------------------------------------
    -- Resolve managerID from @targetEntityName
    ---------------------------------------------------

    declare @mgrID int

    SELECT @mgrID = M_ID
    FROM T_Mgrs
    WHERE (M_Name = @targetEntityName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError = 0 And @myRowCount = 0
    begin
        set @msg = 'Manager "' + @targetEntityName + '" not found in T_Mgrs'
        RAISERROR (@msg, 10, 1)
        return 51000
    end
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @msg = 'Could not look up manager ID for target Entity Name: "' + @targetEntityName + '"'
        RAISERROR (@msg, 10, 1)
        return 51000
    end

    -- if list is empty, we are done
    --
    if LEN(@itemNameList) = 0
        return 0

    ---------------------------------------------------
    -- Create a temporary table that will hold the Entry_ID
    -- values that need to be updated in T_ParamValue
    ---------------------------------------------------
    CREATE TABLE #TmpIDUpdateList (
        TargetID int NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

    declare @delim char(1) = '!'

    declare @inPos int = 1
    declare @inFld varchar(128)

    declare @vPos int = 1
    declare @vFld varchar(128)

    declare @itemID int
    declare @tVal varchar(128)

    declare @EntryID int
    declare @NewEntryID int

    declare @MgrActiveChanged int
    declare @MgrActiveTargetState int

    ---------------------------------------------------
    -- process lists into rows
    -- and insert into DB table
    ---------------------------------------------------
    --
    declare @done int = 0
    declare @count int= 0

    while @done = 0
    begin -- <a>
        set @count = @count + 1
        --print '========== row:' +  + convert(varchar, @count)

        -- get the next field from the item name list
        --
        execute @done = next_field @itemNameList, @delim, @inPos output, @inFld output

        -- process the next field from the item value list
        --
        execute next_field @itemValueList, @delim, @vPos output, @vFld output

        -- resolve item name to item ID
        --
        set @itemID = 0
        SELECT @itemID = paramID
        FROM T_ParamType
        WHERE ParamName = @inFld
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0 or @itemID = 0
        begin
            set @msg = 'Could not resolve item to ID: "' + @inFld + '"'
            RAISERROR (@msg, 10, 1)
            return 51001
        end

        If IsNull(@vFld, '') <> ''
        Begin -- <b>

            -- does entry exist in value table?
            --
            Set @EntryID = -1
            SELECT @tVal = Value, @EntryID = Entry_ID
            FROM T_ParamValue
            WHERE (TypeID = @itemID) AND (MgrID = @mgrID)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                set @msg = 'Error in searching for existing value for item: "' + @inFld + '"'
                RAISERROR (@msg, 10, 1)
                return 51001
            end

            -- if entry exists in value table, update it
            -- otherwise insert it
            --
            if @myRowCount > 0
            begin
                if IsNull(@tVal, '') <> @vFld
                begin
                    UPDATE T_ParamValue
                    SET Value = @vFld
                    WHERE (TypeID = @itemID) AND (MgrID = @mgrID)
                end
            end
            else
            begin
                INSERT INTO T_ParamValue (TypeID, MgrID, Value)
                VALUES (@itemID, @mgrID, @vFld)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount, @NewEntryID = @@Identity

                If @myRowCount > 0
                    Set @EntryID = @NewEntryID
            end

            If Len(@callingUser) > 0 And IsNull(@EntryID, -1) >= 0
            Begin -- <c>
                -- @callingUser is defined
                -- Items need to be updated in T_ParamValue and possibly in T_Event_Log

                -- Add @EntryID to #TmpIDUpdateList
                INSERT INTO #TmpIDUpdateList (TargetID)
                VALUES (@EntryID)

                If @inFld = 'mgractive' or @itemID = 17
                Begin
                    -- MgrActive was changed to True or False

                    Set @MgrActiveChanged = 1

                    If @vFld = 'True'
                        Set @MgrActiveTargetState = 1
                    else
                        Set @MgrActiveTargetState = 0
                End
            End -- </c>

        End -- </b>
    End -- </a>

    If Len(@callingUser) > 0
    Begin
        -- @callingUser is defined
        -- Items need to be updated in T_ParamValue

        Exec alter_entered_by_user_multi_id 'T_ParamValue', 'Entry_ID', @CallingUser, @EntryDateColumnName = 'Last_Affected'

        If @MgrActiveChanged = 1
        Begin
            -- Triggers trig_i_T_ParamValue and trig_u_T_ParamValue make an entry in
            --  T_Event_Log whenever mgractive (param TypeID = 17) is changed

            -- Call alter_event_log_entry_user_multi_id
            -- to alter the Entered_By field in T_Event_Log

            -- Populate #TmpIDUpdateList with Manager ID values, then call alter_event_log_entry_user_multi_id
            Truncate Table #TmpIDUpdateList

            INSERT INTO #TmpIDUpdateList (TargetID)
            VALUES (@mgrID)

            Exec alter_event_log_entry_user_multi_id 1, @MgrActiveTargetState, @callingUser
        End
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------

    return 0

GO
GRANT EXECUTE ON [dbo].[add_update_manager_params] TO [Mgr_Config_Admin] AS [dbo]
GO
