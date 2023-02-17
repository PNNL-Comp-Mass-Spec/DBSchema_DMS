/****** Object:  StoredProcedure [dbo].[set_param_for_manager_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_param_for_manager_list]
/****************************************************
**
**  Desc:
**  Set value for given param to given value
**  for all managers whose IDs are in the
**  temporary table "#ManagerIDList" that is create by caller
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/31/2007
**          03/30/2009 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**          04/16/2009 mem - Now calling update_single_mgr_param_work to perform the updates
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramValue varchar(512),           -- The new value to assign for parameter @paramType
    @paramType varchar(50),             -- The parameter name
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Create a temporary table that will hold the Entry_ID
    -- values that need to be updated in T_ParamValue
    ---------------------------------------------------
    CREATE TABLE #TmpParamValueEntriesToUpdate (
        EntryID int NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_TmpParamValueEntriesToUpdate ON #TmpParamValueEntriesToUpdate (EntryID)


    -- Assure that @paramValue is not null
    Set @paramValue = IsNull(@paramValue, '')

    ---------------------------------------------------
    -- Retrieve the parameter ID from the parameter Type table
    ---------------------------------------------------
    declare @paramID int
    set @paramID = 0
    --
    select @paramID = ParamID
    from T_ParamType
    where ParamName = @paramType
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to resolve param ID'
        return 51100
    end
    --
    if @paramID = 0
    begin
        set @message = 'Could not resolve param ID'
        return 51101
    end

    ---------------------------------------------------
    -- Add value entries that don't already exist for managers in list
    -- We first set the value to '##_DummyParamValue_##'; we'll next
    -- update it using update_single_mgr_param_work
    ---------------------------------------------------

    INSERT INTO T_ParamValue
        (TypeID, Value, MgrID)
    SELECT @paramID, '##_DummyParamValue_##', #ManagerIDList.ID
    FROM #ManagerIDList
    WHERE NOT EXISTS
    (
        SELECT * FROM T_ParamValue
        WHERE T_ParamValue.MgrID = #ManagerIDList.ID AND T_ParamValue.TypeID = @paramID
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to enter new param values'
        return 51102
    end

    ---------------------------------------------------
    -- Find the @paramID entries for the Managers in #ManagerIDList
    ---------------------------------------------------
    --
    INSERT INTO #TmpParamValueEntriesToUpdate (EntryID)
    SELECT PV.Entry_ID
    FROM T_ParamValue PV INNER JOIN
         #ManagerIDList M ON PV.MgrID = M.ID
    WHERE PV.TypeID = @paramID AND
          IsNull(PV.[Value], '') <> @paramValue
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        RAISERROR ('Error finding Manager params to update', 10, 1)
        return 51103
    end

    If @myRowCount > 0
    Begin
        ---------------------------------------------------
        -- Call update_single_mgr_param_work to perform the update, then call
        -- alter_entered_by_user_multi_id and alter_event_log_entry_user_multi_id for @callingUser
        ---------------------------------------------------
        --
        exec @myError = update_single_mgr_param_work @paramType, @paramValue, @callingUser
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT EXECUTE ON [dbo].[set_param_for_manager_list] TO [Mgr_Config_Admin] AS [dbo]
GO
