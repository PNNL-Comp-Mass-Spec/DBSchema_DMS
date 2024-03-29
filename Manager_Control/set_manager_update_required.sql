/****** Object:  StoredProcedure [dbo].[set_manager_update_required] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[set_manager_update_required]
/****************************************************
**
**  Desc:
**      Sets ManagerUpdateRequired to true for the given list of managers
**      If @ManagerList is blank, then sets it to true for all "Analysis Tool Manager" managers
**
**  Auth:   mem
**  Date:   01/24/2009 mem - Initial version
**          04/17/2014 mem - Expanded @ManagerList to varchar(max) and added parameter @showTable
**          02/01/2023 mem - Use new view name
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerList varchar(max) = '',
    @showTable tinyint = 0,
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Set @showTable = IsNull(@showTable, 0)
    Set @message = ''


    Declare @mgrID int
    Declare @ParamID int

    CREATE TABLE #TmpManagerList (
        ManagerName varchar(128) NOT NULL,
        MgrID int NULL
    )

    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    Set @ManagerList = IsNull(@ManagerList, '')

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
    -- Lookup the ParamID value for 'ManagerUpdateRequired'
    ---------------------------------------------------

    Set @ParamID = 0
    --
    SELECT @ParamID = ParamID
    FROM T_ParamType
    WHERE (ParamName = 'ManagerUpdateRequired')

    ---------------------------------------------------
    -- Make sure each manager in #TmpManagerList has an entry
    --  in T_ParamValue for 'ManagerUpdateRequired'
    ---------------------------------------------------

    INSERT INTO T_ParamValue (MgrID, TypeID, Value)
    SELECT A.MgrID, @ParamID, 'False'
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
        Set @message = 'Added entry for "ManagerUpdateRequired" to T_ParamValue for ' + Convert(varchar(12), @myRowCount) + ' manager'
        If @myRowCount > 1
            Set @message = @message + 's'

        Print @message
    End

    ---------------------------------------------------
    -- Update the 'ManagerUpdateRequired' entry for each manager in #TmpManagerList
    ---------------------------------------------------

    UPDATE T_ParamValue
    SET VALUE = 'True'
    FROM T_ParamValue
         INNER JOIN #TmpManagerList
           ON T_ParamValue.MgrID = #TmpManagerList.MgrID
    WHERE (T_ParamValue.TypeID = @ParamID) AND
          T_ParamValue.Value <> 'True'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount <> 0
    Begin
        Set @message = 'Set "ManagerUpdateRequired" to True for ' + Convert(varchar(12), @myRowCount) + ' manager'
        If @myRowCount > 1
            Set @message = @message + 's'

        Print @message
    End

    If @showTable <> 0
    Begin
        SELECT U.*
        FROM V_Analysis_Mgr_Params_Update_Required U
             INNER JOIN #TmpManagerList L
               ON U.Mgr_ID = L.MgrId
        ORDER BY Manager DESC
    End

    ---------------------------------------------------
    -- Exit the procedure
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT EXECUTE ON [dbo].[set_manager_update_required] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[set_manager_update_required] TO [MTUser] AS [dbo]
GO
