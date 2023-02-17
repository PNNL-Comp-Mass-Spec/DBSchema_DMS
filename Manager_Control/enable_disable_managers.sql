/****** Object:  StoredProcedure [dbo].[enable_disable_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[enable_disable_managers]
/****************************************************
**
**  Desc:  Enables or disables all managers of the given type
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/12/2007
**          05/09/2008 mem - Added parameter @ManagerNameList
**          06/09/2011 mem - Now filtering on MT_Active > 0 in T_MgrTypes
**                         - Now allowing @ManagerNameList to be All when @Enable = 1
**          10/12/2017 mem - Allow @ManagerTypeID to be 0 if @ManagerNameList is provided
**          03/28/2018 mem - Use different messages when updating just one manager
**          02/12/2020 mem - Rename parameter to @infoOnly
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @enable tinyint,                        -- 0 to disable, 1 to enable
    @managerTypeID int=11,                  -- Defined in table T_MgrTypes.  8=Space, 9=DataImport, 11=Analysis Tool Manager, 15=CaptureTaskManager
    @managerNameList varchar(4000) = '',    -- Required when @Enable = 1.  Only managers specified here will be enabled, though you can use "All" to enable All managers.  When @Enable = 0, if this parameter is blank (or All) then all managers of the given type will be disabled; supports the % wildcard
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    Declare @NewValue varchar(32)
    Declare @ManagerTypeName varchar(128)
    Declare @ActiveStateDescription varchar(16)
    Declare @CountToUpdate int
    Declare @CountUnchanged int

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @ManagerNameList = IsNull(@ManagerNameList, '')
    Set @infoOnly = IsNull(@infoOnly, 0)

    If @Enable Is Null
    Begin
        set @myError  = 40000
        Set @message = '@Enable cannot be null'
        SELECT @message AS Message
        Goto Done
    End

    If @ManagerTypeID Is Null
    Begin
        set @myError = 40001
        Set @message = '@ManagerTypeID cannot be null'
        SELECT @message AS Message
        Goto Done
    End

    If @ManagerTypeID = 0 And Len(@ManagerNameList) > 0 And @ManagerNameList <> 'All'
    Begin
        Set @ManagerTypeName = 'Any'
    End
    Else
    Begin
        -- Make sure @ManagerTypeID is valid
        Set @ManagerTypeName = ''
        SELECT @ManagerTypeName = MT_TypeName
        FROM T_MgrTypes
        WHERE MT_TypeID = @ManagerTypeID AND
            MT_Active > 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            If Exists (SELECT * FROM T_MgrTypes WHERE MT_TypeID = @ManagerTypeID AND MT_Active = 0)
                Set @message = '@ManagerTypeID ' + Convert(varchar(12), @ManagerTypeID) + ' has MT_Active = 0 in T_MgrTypes; unable to continue'
            Else
                Set @message = '@ManagerTypeID ' + Convert(varchar(12), @ManagerTypeID) + ' not found in T_MgrTypes'

            SELECT @message AS Message
            set @myError  = 40002
            Goto Done
        End
    End

    If @Enable <> 0 AND Len(@ManagerNameList) = 0
    Begin
        Set @message = '@ManagerNameList cannot be blank when @Enable is non-zero; to update all managers, set @ManagerNameList to All'
        SELECT @message AS Message
        set @myError  = 40003
        Goto Done
    End

    -----------------------------------------------
    -- Creata a temporary table
    -----------------------------------------------

    CREATE TABLE #TmpManagerList (
        Manager_Name varchar(128) NOT NULL
    )

    If Len(@ManagerNameList) > 0 And @ManagerNameList <> 'All'
    Begin
        -- Populate #TmpManagerList using parse_manager_name_list

        Exec @myError = parse_manager_name_list @ManagerNameList, @RemoveUnknownManagers=1, @message=@message output

        If @myError <> 0
        Begin
            If Len(@message) = 0
                Set @message = 'Error calling parse_manager_name_list: ' + Convert(varchar(12), @myError)

            Goto Done
        End

        If @ManagerTypeID > 0
        Begin
            -- Delete entries from #TmpManagerList that don't match entries in M_Name of the given type
            DELETE #TmpManagerList
            FROM #TmpManagerList U LEFT OUTER JOIN
                T_Mgrs M ON M.M_Name = U.Manager_Name AND M.M_TypeID = @ManagerTypeID
            WHERE M.M_Name Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = 'Found ' + convert(varchar(12), @myRowCount) + ' entries in @ManagerNameList that are not ' + @ManagerTypeName + ' managers'
                Set @message = ''
            End
        End

    End
    Else
    Begin
        -- Populate #TmpManagerList with all managers in T_Mgrs
        --
        INSERT INTO #TmpManagerList (Manager_Name)
        SELECT M_Name
        FROM T_Mgrs
        WHERE M_TypeID = @ManagerTypeID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End


    -- Set @NewValue based on @Enable
    If @Enable = 0
    Begin
        Set @NewValue = 'False'
        Set @ActiveStateDescription = 'Inactive'
    End
    Else
    Begin
        Set @NewValue = 'True'
        Set @ActiveStateDescription = 'Active'
    End

    -- Count the number of managers that need to be updated
    Set @CountToUpdate = 0
    SELECT @CountToUpdate = COUNT(*)
    FROM T_ParamValue PV
         INNER JOIN T_ParamType PT
           ON PV.TypeID = PT.ParamID
         INNER JOIN T_Mgrs M
           ON PV.MgrID = M.M_ID
         INNER JOIN T_MgrTypes MT
           ON M.M_TypeID = MT.MT_TypeID
         INNER JOIN #TmpManagerList U
           ON M.M_Name = U.Manager_Name
    WHERE PT.ParamName = 'mgractive' AND
          PV.Value <> @NewValue AND
          MT.MT_Active > 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -- Count the number of managers already in the target state
    Set @CountUnchanged = 0
    SELECT @CountUnchanged = COUNT(*)
    FROM T_ParamValue PV
         INNER JOIN T_ParamType PT
           ON PV.TypeID = PT.ParamID
         INNER JOIN T_Mgrs M
           ON PV.MgrID = M.M_ID
         INNER JOIN T_MgrTypes MT
           ON M.M_TypeID = MT.MT_TypeID
         INNER JOIN #TmpManagerList U
           ON M.M_Name = U.Manager_Name
    WHERE PT.ParamName = 'mgractive' AND
          PV.Value = @NewValue AND
          MT.MT_Active > 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If @CountToUpdate = 0
    Begin
        If @CountUnchanged = 0
        Begin
            If Len(@ManagerNameList) > 0
            Begin
                If @ManagerTypeID = 0
                    Set @message = 'None of the managers in @ManagerNameList was recognized'
                Else
                    Set @message = 'No ' + @ManagerTypeName + ' managers were found matching @ManagerNameList'
            End
            Else
            Begin
                Set @message = 'No ' + @ManagerTypeName + ' managers were found in T_Mgrs'
            End
        End
        Else
        Begin
            If @CountUnchanged = 1
            Begin
                Set @message = 'The manager is already ' + @ActiveStateDescription
            End
            Else
            Begin
                If @ManagerTypeID = 0
                    Set @message = 'All ' + Convert(varchar(12), @CountUnchanged) + ' managers are already ' + @ActiveStateDescription
                Else
                    Set @message = 'All ' + Convert(varchar(12), @CountUnchanged) + ' ' + @ManagerTypeName + ' managers are already ' + @ActiveStateDescription
            End
        End

        SELECT @message AS Message

    End
    Else
    Begin
        If @infoOnly <> 0
        Begin
            SELECT Convert(varchar(32), PV.Value + '-->' + @NewValue) AS State_Change_Preview,
                   PT.ParamName AS Parameter_Name,
                   M.M_Name AS Manager_Name,
                   MT.MT_TypeName AS Manager_Type
            FROM T_ParamValue PV
                 INNER JOIN T_ParamType PT
                   ON PV.TypeID = PT.ParamID
                 INNER JOIN T_Mgrs M
                   ON PV.MgrID = M.M_ID
                 INNER JOIN T_MgrTypes MT
                   ON M.M_TypeID = MT.MT_TypeID
                 INNER JOIN #TmpManagerList U
                   ON M.M_Name = U.Manager_Name
            WHERE PT.ParamName = 'mgractive' AND
                  PV.Value <> @NewValue AND
                  MT.MT_Active > 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            UPDATE T_ParamValue
            SET VALUE = @NewValue
            FROM T_ParamValue PV
                 INNER JOIN T_ParamType PT
                   ON PV.TypeID = PT.ParamID
                 INNER JOIN T_Mgrs M
                   ON PV.MgrID = M.M_ID
                 INNER JOIN T_MgrTypes MT
                   ON M.M_TypeID = MT.MT_TypeID
                 INNER JOIN #TmpManagerList U
                   ON M.M_Name = U.Manager_Name
            WHERE PT.ParamName = 'mgractive' AND
                  PV.Value <> @NewValue AND
                  MT.MT_Active > 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 1 And @CountUnchanged = 0
            Begin
                Set @message = 'The manager is now ' + @ActiveStateDescription
            End
            Else
            Begin
                If @ManagerTypeID = 0
                    Set @message = 'Set ' + Convert(varchar(12), @myRowCount) + ' managers to state ' + @ActiveStateDescription
                Else
                    Set @message = 'Set ' + Convert(varchar(12), @myRowCount) + ' ' + @ManagerTypeName + ' managers to state ' + @ActiveStateDescription

                If @CountUnchanged <> 0
                    Set @message = @message + ' (' + Convert(varchar(12), @CountUnchanged) + ' managers were already ' + @ActiveStateDescription + ')'
            End

            SELECT @message AS Message
        End
    End

Done:
    Return @myError

GO
GRANT EXECUTE ON [dbo].[enable_disable_managers] TO [Mgr_Config_Admin] AS [dbo]
GO
