/****** Object:  StoredProcedure [dbo].[update_single_mgr_param_work] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_single_mgr_param_work]
/****************************************************
**
**  Desc:
**  Changes single manager param for the EntryID values
**  defined in table #TmpParamValueEntriesToUpdate (created by the calling procedure)
**
**  Example table creation code:
**    CREATE TABLE #TmpParamValueEntriesToUpdate (EntryID int NOT NULL)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   04/16/2009
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramName varchar(32),             -- The parameter name
    @newValue varchar(128),             -- The new value to assign for this parameter
    @callingUser varchar(128) = ''
)
AS
    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @ParamID int
    Declare @TargetState int

    Declare @message varchar(512)
    Set @message = ''

    -- Validate that @paramName is not blank
    If IsNull(@paramName, '') = ''
    Begin
        Set @message = 'Parameter Name is empty or null'
        RAISERROR (@message, 10, 1)
        return 51315
    End

    -- Assure that @newValue is not null
    Set @newValue = IsNull(@newValue, '')


    -- Lookup the ParamID for param @paramName
    Set @ParamID = 0
    SELECT @ParamID = ParamID
    FROM T_ParamType
    WHERE (ParamName = @paramName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Unknown Parameter Name: ' + @paramName
        RAISERROR (@message, 10, 1)
        return 51316
    End

    ---------------------------------------------------
    -- Update the values defined in #TmpParamValueEntriesToUpdate
    ---------------------------------------------------
    --
    UPDATE T_ParamValue
    SET [Value] = @newValue
    WHERE Entry_ID IN (SELECT EntryID FROM #TmpParamValueEntriesToUpdate) AND
          IsNull([Value], '') <> @newValue
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @message = 'Error trying to update Manager params'
        RAISERROR (@message, 10, 1)
        return 51310
    end


    If @myRowCount > 0 And Len(@callingUser) > 0
    Begin
        -- @callingUser is defined
        -- Items need to be updated in T_ParamValue and possibly in T_Event_Log

        ---------------------------------------------------
        -- Create a temporary table that will hold the Entry_ID
        -- values that need to be updated in T_ParamValue
        ---------------------------------------------------
        CREATE TABLE #TmpIDUpdateList (
            TargetID int NOT NULL
        )

        CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

        -- Populate #TmpIDUpdateList with Entry_ID values for T_ParamValue, then call alter_entered_by_user_multi_id
        --
        INSERT INTO #TmpIDUpdateList (TargetID)
        SELECT EntryID
        FROM #TmpParamValueEntriesToUpdate

        Exec alter_entered_by_user_multi_id 'T_ParamValue', 'Entry_ID', @CallingUser, @EntryDateColumnName = 'Last_Affected'


        If @paramName = 'mgractive' or @ParamID = 17
        Begin
            -- Triggers trig_i_T_ParamValue and trig_u_T_ParamValue make an entry in
            --  T_Event_Log whenever mgractive (param TypeID = 17) is changed

            -- Call alter_event_log_entry_user_multi_id
            -- to alter the Entered_By field in T_Event_Log

            If @newValue = 'True'
                Set @TargetState = 1
            else
                Set @TargetState = 0

            -- Populate #TmpIDUpdateList with Manager ID values, then call alter_event_log_entry_user_multi_id
            Truncate Table #TmpIDUpdateList

            INSERT INTO #TmpIDUpdateList (TargetID)
            SELECT MgrID
            FROM T_ParamValue
            WHERE Entry_ID IN (SELECT EntryID FROM #TmpParamValueEntriesToUpdate)

            Exec alter_event_log_entry_user_multi_id 1, @TargetState, @callingUser
        End

    End

    Return @myError

GO
