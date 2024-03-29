/****** Object:  StoredProcedure [dbo].[set_manager_error_cleanup_mode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_manager_error_cleanup_mode]
/****************************************************
**
**  Desc:
**      Sets ManagerErrorCleanupMode to @CleanupMode for the given list of managers
**      If @ManagerList is blank, then sets it to @CleanupMode for all "Analysis Tool Manager" managers
**
**  Auth:   mem
**  Date:   09/10/2009 mem - Initial version
**          09/29/2014 mem - Expanded @ManagerList to varchar(max) and added parameters @showTable and @infoOnly
**                         - Fixed where clause bug in final update query
**          01/30/2023 mem - Use new column name in view
**          02/01/2023 mem - Use new view name
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerList varchar(max) = '',
    @cleanupMode tinyint = 1,                -- 0 = No auto cleanup, 1 = Attempt auto cleanup once, 2 = Auto cleanup always
    @showTable tinyint = 1,
    @infoOnly tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @mgrID int
    Declare @ParamID int
    Declare @CleanupModeString varchar(12)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @ManagerList = IsNull(@ManagerList, '')
    Set @CleanupMode = IsNull(@CleanupMode, 1)
    Set @showTable = IsNull(@showTable, 1)
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    If @CleanupMode < 0
        Set @CleanupMode = 0

    If @CleanupMode > 2
        Set @CleanupMode = 2

    CREATE TABLE #TmpManagerList (
        ManagerName varchar(128) NOT NULL,
        MgrID int NULL
    )

    ---------------------------------------------------
    -- Confirm that the manager names are valid
    ---------------------------------------------------

    If Len(@ManagerList) > 0
        INSERT INTO #TmpManagerList (ManagerName)
        SELECT Value
        FROM dbo.parse_delimited_list(@ManagerList, ',')
        WHERE Len(IsNull(Value, '')) > 0
    Else
        INSERT INTO #TmpManagerList (ManagerName)
        SELECT M_Name
        FROM T_Mgrs
        WHERE (M_TypeID = 11)

    UPDATE #TmpManagerList
    SET MgrID = T_Mgrs.M_ID
    FROM #TmpManagerList INNER JOIN T_Mgrs
            ON T_Mgrs.M_Name = #TmpManagerList.ManagerName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    DELETE FROM #TmpManagerList
    WHERE MgrID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount <> 0
    Begin
        Set @message = 'Removed ' + Convert(varchar(12), @myRowCount) + ' invalid manager'
        If @myRowCount > 1
            Set @message = @message + 's'

        Set @message = @message + ' from #TmpManagerList'
        Print @message
    End

    ---------------------------------------------------
    -- Lookup the ParamID value for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    Set @ParamID = 0
    --
    SELECT @ParamID = ParamID
    FROM T_ParamType
    WHERE (ParamName = 'ManagerErrorCleanupMode')

    ---------------------------------------------------
    -- Make sure each manager in #TmpManagerList has an entry
    --  in T_ParamValue for 'ManagerErrorCleanupMode'
    ---------------------------------------------------

    INSERT INTO T_ParamValue (MgrID, TypeID, Value)
    SELECT A.MgrID, @ParamID, '0'
    FROM ( SELECT MgrID
           FROM #TmpManagerList
         ) A
         LEFT OUTER JOIN
          ( SELECT #TmpManagerList.MgrID
            FROM #TmpManagerList
                 INNER JOIN T_ParamValue
                   ON #TmpManagerList.MgrID = T_ParamValue.MgrID
            WHERE T_ParamValue.TypeID = @ParamID
         ) B
           ON A.MgrID = B.MgrID
    WHERE B.MgrID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount <> 0
    Begin
        Set @message = 'Added entry for "ManagerErrorCleanupMode" to T_ParamValue for ' + Convert(varchar(12), @myRowCount) + ' manager'
        If @myRowCount > 1
            Set @message = @message + 's'

        Print @message
    End

    ---------------------------------------------------
    -- Update the 'ManagerErrorCleanupMode' entry for each manager in #TmpManagerList
    ---------------------------------------------------

    Set @CleanupModeString = Convert(varchar(12), @CleanupMode)

    If @infoOnly <> 0
    Begin
        SELECT MP.*, @CleanupMode As NewCleanupMode
        FROM V_Analysis_Mgr_Params_Active_And_Debug_Level MP
            INNER JOIN #TmpManagerList
            ON MP.Mgr_ID = #TmpManagerList.MgrID
        WHERE MP.Param_Type_ID = 120
        ORDER BY MP.Manager
    End
    Else
    Begin

        UPDATE T_ParamValue
        SET Value = @CleanupModeString
        FROM T_ParamValue
            INNER JOIN #TmpManagerList
            ON T_ParamValue.MgrID = #TmpManagerList.MgrID
        WHERE T_ParamValue.TypeID = @ParamID AND
            T_ParamValue.Value <> @CleanupModeString
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount <> 0
        Begin
            Set @message = 'Set "ManagerErrorCleanupMode" to ' + @CleanupModeString + ' for ' + Convert(varchar(12), @myRowCount) + ' manager'
            If @myRowCount > 1
                Set @message = @message + 's'

            Print @message
        End
    End

    ---------------------------------------------------
    -- Show the new values
    ---------------------------------------------------

    If @infoOnly = 0 And @showTable <> 0
    Begin
        SELECT MP.*
        FROM V_Analysis_Mgr_Params_Active_And_Debug_Level MP
            INNER JOIN #TmpManagerList
            ON MP.Mgr_ID = #TmpManagerList.MgrID
        WHERE MP.Param_Type_ID = 120
        ORDER BY MP.Manager
    End

    ---------------------------------------------------
    -- Exit the procedure
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT EXECUTE ON [dbo].[set_manager_error_cleanup_mode] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_manager_error_cleanup_mode] TO [MTUser] AS [dbo]
GO
