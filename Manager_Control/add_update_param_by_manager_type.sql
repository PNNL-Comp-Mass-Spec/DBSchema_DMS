/****** Object:  StoredProcedure [dbo].[add_update_param_by_manager_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_param_by_manager_type]
/****************************************************
**
**  Desc:
**  Adds or Updates a single manager params for set of given manager types
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   jds
**  Date:   09/14/2007
**          04/16/2009 mem - Added optional parameter @callingUser; if provided, then will populate field Entered_By with this name
**          01/12/2011 mem - Now updating @newValue to '' if null
**                         - Added parameter @AssociateParameterWithManagers
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramValue varchar(32),            -- The new parameter's name
    @newValue varchar(128) = '',        -- The default value for the new parameter
    @managerTypeIDList varchar(2048),
    @mode varchar(12) = 'add', --or 'update'
    @callingUser varchar(128) = '',
    @AssociateParameterWithManagers tinyint = 1     -- If 1, then adds an entry to T_ParamValue for all managers with types defined in @managerTypeIDList; otherwise, does not update T_ParamValue
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @msg varchar(500)
    set @msg = ''

    Set @AssociateParameterWithManagers = IsNull(@AssociateParameterWithManagers, 1)

    ---------------------------------------------------
    -- Validate @paramValue
    ---------------------------------------------------
    Set @paramValue = IsNull(@paramValue, '')
    If @paramValue = ''
    Begin
        Set @msg = 'The new parameter name is blank; unable to continue'
        RAISERROR (@msg, 10, 1)
        return 51310
    End

    Set @newValue = IsNull(@newValue, '')

    ---------------------------------------------------
    -- Check to see if parameter already exists
    ---------------------------------------------------
    If Exists (SELECT * FROM T_ParamType WHERE ParamName = @paramValue)
    Begin
        Set @msg = 'The parameter name "' + @paramValue + '" already exists.'
        RAISERROR (@msg, 10, 1)
        return 51311
    end

    ---------------------------------------------------
    -- Create and populate a temporary table to hold the manager type ID values in @managerTypeIDList
    ---------------------------------------------------
    CREATE TABLE #TmpMgrTypeIDList (
        MgrTypeID int NOT NULL
    )

    INSERT INTO #TmpMgrTypeIDList (MgrTypeID)
    SELECT Convert(int, Item)
    FROM make_table_from_list(@managerTypeIDList)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @msg = 'Error parsing the manager type ID list'
        RAISERROR (@msg, 10, 1)
        return 51312
    End

    ---------------------------------------------------
    -- Check for invalid TypeID values in #TmpMgrTypeIDList
    ---------------------------------------------------

    Set @msg = ''
    SELECT @msg = @msg + Convert(varchar(12), MgrTypeID) + ', '
    FROM #TmpMgrTypeIDList Src LEFT OUTER JOIN T_MgrTypes MT
         ON Src.MgrTypeID = MT.MT_TypeID
    WHERE MT.MT_TypeID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        -- Remove the trailing comma (Note: we must use Len(@msg)-1 since the Len() function trims trailing spaces when determing length)
        Set @msg = Substring(@msg, 1, Len(@msg)-1)
        Set @msg = 'One or more Manager Type ID values are invalid: ' + @msg
        RAISERROR (@msg, 10, 1)
        return 51312
    End

    ---------------------------------------------------
    -- Add the new parameter to the parameter Type table
    ---------------------------------------------------
    declare @pID int
    set @pID = 0

    INSERT INTO T_ParamType(ParamName)
    VALUES(@paramValue)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    set @pID = IDENT_CURRENT('T_ParamType')
    --
    if @myError <> 0
    begin
        set @msg = 'Error trying to add new parameter: "' + @paramValue + '".'
        RAISERROR (@msg, 10, 1)
        return 51313
    end

    ---------------------------------------------------
    -- Add the new parameter to mapping table and param value table
    -- for all Manager Types in list
    ---------------------------------------------------

    if @mode = 'add'
    begin
        INSERT INTO T_MgrType_ParamType_Map(MgrTypeID, ParamTypeID, DefaultValue)
        SELECT MgrTypeID, @pID, @newValue
        FROM #TmpMgrTypeIDList
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            RAISERROR ('Error trying to add Manager params Mapping table', 10, 1)
            return 51314
        end

        If @AssociateParameterWithManagers > 0
        Begin
            INSERT INTO T_ParamValue(TypeID, Value, MgrID)
            SELECT @pID, @newValue, M.M_ID
            FROM T_Mgrs M INNER JOIN
                #TmpMgrTypeIDList MTL ON M.M_TypeID = MTL.MgrTypeID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
            begin
                RAISERROR ('Error trying to add Manager params to Param Value table', 10, 1)
                return 51315
            end
        End

        If Len(@callingUser) > 0
        Begin
            -- @callingUser is defined
            -- Items need to be updated in T_ParamValue

            ---------------------------------------------------
            -- Create a temporary table that will hold the Entry_ID
            -- values that need to be updated in T_ParamValue
            ---------------------------------------------------
            CREATE TABLE #TmpIDUpdateList (
                TargetID int NOT NULL
            )

            CREATE UNIQUE CLUSTERED INDEX #IX_TmpIDUpdateList ON #TmpIDUpdateList (TargetID)

            -- Populate #TmpIDUpdateList
            INSERT INTO #TmpIDUpdateList (TargetID)
            SELECT PV.Entry_ID
            FROM T_ParamValue PV INNER JOIN
                 T_Mgrs M ON PV.MgrID = M.M_ID INNER JOIN
                 #TmpMgrTypeIDList MTL ON M.M_TypeID = MTL.MgrTypeID
            WHERE PV.TypeID = @pID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Exec alter_entered_by_user_multi_id 'T_ParamValue', 'Entry_ID', @CallingUser, @EntryDateColumnName = 'Last_Affected'
        End

    end

    return @myError

GO
GRANT EXECUTE ON [dbo].[add_update_param_by_manager_type] TO [Mgr_Config_Admin] AS [dbo]
GO
