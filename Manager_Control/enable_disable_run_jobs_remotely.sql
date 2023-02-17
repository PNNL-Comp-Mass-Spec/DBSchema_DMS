/****** Object:  StoredProcedure [dbo].[enable_disable_run_jobs_remotely] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[enable_disable_run_jobs_remotely]
/****************************************************
**
**  Desc:   Enables or disables a manager to run jobs remotely
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/28/2018 mem - Initial version
**          03/29/2018 mem - Add parameter @addMgrParamsIfMissing
**          02/12/2020 mem - Rename parameter to @infoOnly
**          02/03/2023 bcg - Use renamed view V_Mgr_Params
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @enable tinyint,                        -- 0 to disable running jobs remotely, 1 to enable running jobs remotely
    @managerNameList varchar(4000) = '',    -- Manager(s) to update; supports % for wildcards
    @infoOnly tinyint = 0,
    @addMgrParamsIfMissing tinyint = 0,      -- When 1, if manger(s) are missing parameters RunJobsRemotely or RemoteHostName, will auto-add those parameters
    @message varchar(512) = '' output
)
AS
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    Declare @NewValue varchar(32)
    Declare @ActiveStateDescription varchar(32)
    Declare @CountToUpdate int
    Declare @CountUnchanged int

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @managerNameList = IsNull(@managerNameList, '')
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @addMgrParamsIfMissing = IsNull(@addMgrParamsIfMissing, 0)

    If @enable Is Null
    Begin
        set @myError  = 40000
        Set @message = '@enable cannot be null'
        SELECT @message AS Message
        Goto Done
    End

    If Len(@managerNameList) = 0
    Begin
        set @myError  = 40003
        Set @message = '@managerNameList cannot be blank'
        SELECT @message AS Message
        Goto Done
    End

    -----------------------------------------------
    -- Creata a temporary table
    -----------------------------------------------

    CREATE TABLE #TmpManagerList (
        Manager_Name varchar(128) NOT NULL
    )

    -- Populate #TmpMangerList using parse_manager_name_list
    --
    Exec @myError = parse_manager_name_list @managerNameList, @RemoveUnknownManagers=1, @message=@message output

    If @myError <> 0
    Begin
        If Len(@message) = 0
            Set @message = 'Error calling parse_manager_name_list: ' + Convert(varchar(12), @myError)

        Goto Done
    End

    -- Set @NewValue based on @enable
    If @enable = 0
    Begin
        Set @NewValue = 'False'
        Set @ActiveStateDescription = 'run jobs locally'
    End
    Else
    Begin
        Set @NewValue = 'True'
        Set @ActiveStateDescription = 'run jobs remotely'
    End

    If Exists (Select * From #TmpManagerList Where Manager_Name = 'Default_AnalysisMgr_Params')
    Begin
        Delete From #TmpManagerList Where Manager_Name = 'Default_AnalysisMgr_Params'

        Set @message = 'For safety, not updating RunJobsRemotely for manager Default_AnalysisMgr_Params'

        If Exists (Select * From #TmpManagerList)
        Begin
            -- #TmpManagerList contains other managers; update them
            Print @message
        End
        Else
        Begin
            -- #TmpManagerList is now empty; abort
            SELECT @message AS Message
            Goto Done
        End
    End

    If @addMgrParamsIfMissing > 0
    Begin -- <a>
        Declare @mgrName varchar(128) = ''
        Declare @mgrId int = 0
        Declare @paramTypeId int = 0
        Declare @continue tinyint = 1

        While @continue > 0
        Begin -- <b>
            SELECT TOP 1 @mgrName = #TmpManagerList.Manager_Name,
                         @mgrId = T_Mgrs.M_ID
            FROM #TmpManagerList
                 INNER JOIN T_Mgrs
                   ON #TmpManagerList.Manager_Name = T_Mgrs.M_Name
            WHERE Manager_Name > @mgrName
            ORDER BY Manager_Name
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin -- <c>
                If Not Exists (SELECT * FROM V_Mgr_Params Where Parameter_Name = 'RunJobsRemotely' And Manager_Name = @mgrName)
                Begin -- <d1>
                    Set @paramTypeId = null
                    SELECT @paramTypeId = ParamID
                    FROM [T_ParamType]
                    Where ParamName = 'RunJobsRemotely'

                    If IsNull(@paramTypeId, 0) = 0
                    Begin
                        Print 'Error: could not find parameter "RunJobsRemotely" in [T_ParamType]'
                    End
                    Else
                    Begin
                        If @infoOnly > 0
                        Begin
                            Print 'Create parameter RunJobsRemotely for Manager ' + @mgrName + ', value ' + @newValue

                            -- Actually do go ahead and create the parameter, but use a value of False even if @newValue is True
                            -- We need to do this so the managers are included in the query below with PT.ParamName = 'RunJobsRemotely'
                            Insert Into T_ParamValue (MgrID, TypeID, Value)
                            Values (@mgrId, @paramTypeId, 'False')
                        End
                        Else
                        Begin
                            Insert Into T_ParamValue (MgrID, TypeID, Value)
                            Values (@mgrId, @paramTypeId, @newValue)
                        End
                    End
                End -- </d1>

                If Not Exists (SELECT * FROM V_Mgr_Params Where Parameter_Name = 'RemoteHostName' And Manager_Name = @mgrName)
                Begin -- <d2>
                    Set @paramTypeId = null
                    SELECT @paramTypeId = ParamID
                    FROM [T_ParamType]
                    Where ParamName = 'RemoteHostName'

                    If IsNull(@paramTypeId, 0) = 0
                    Begin
                        Print 'Error: could not find parameter "RemoteHostName" in [T_ParamType]'
                    End
                    Else
                    Begin
                        If @infoOnly > 0
                        Begin
                            Print 'Create parameter RemoteHostName for Manager ' + @mgrName + ', value PrismWeb2'
                        End
                        Else
                        Begin
                            Insert Into T_ParamValue (MgrID, TypeID, Value)
                            Values (@mgrId, @paramTypeId, 'PrismWeb2')
                        End
                    End
                End -- </d1>
            End -- </c>
        End -- </b>
    End -- </a>

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
    WHERE PT.ParamName = 'RunJobsRemotely' AND
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
    WHERE PT.ParamName = 'RunJobsRemotely' AND
          PV.Value = @NewValue AND
          MT.MT_Active > 0
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    If @CountToUpdate = 0
    Begin
        If @CountUnchanged = 0
        Begin
            Set @message = 'No managers were found matching @managerNameList'
        End
        Else
        Begin
            If @CountUnchanged = 1
                Set @message = 'The manager is already set to ' + @ActiveStateDescription
            Else
                Set @message = 'All ' + Convert(varchar(12), @CountUnchanged) + ' managers are already set to ' + @ActiveStateDescription
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
            WHERE PT.ParamName = 'RunJobsRemotely' AND
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
            WHERE PT.ParamName = 'RunJobsRemotely' AND
                  PV.Value <> @NewValue AND
                  MT.MT_Active > 0
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 1 And @CountUnchanged = 0
            Begin
                Set @message = 'Configured the manager to ' + @ActiveStateDescription
            End
            Else
            Begin
                Set @message = 'Configured ' + Convert(varchar(12), @myRowCount) + ' managers to ' + @ActiveStateDescription

                If @CountUnchanged <> 0
                    Set @message = @message + ' (' + Convert(varchar(12), @CountUnchanged) + ' managers were already set to ' + @ActiveStateDescription + ')'
            End

            SELECT @message AS Message
        End
    End

Done:
    Return @myError

GO
