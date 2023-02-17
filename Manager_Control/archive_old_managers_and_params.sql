/****** Object:  StoredProcedure [dbo].[archive_old_managers_and_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[archive_old_managers_and_params]
/****************************************************
**
**  Desc:   Moves managers from T_Mgrs to T_OldManagers
**          and moves manager parameters from T_ParamValue to T_ParamValue_OldManagers
**
**          To reverse this process, use procedure unarchive_old_managers_and_params
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/14/2015 mem - Initial version
**          02/25/2016 mem - Add Set XACT_ABORT On
**          04/22/2016 mem - Now updating M_Comment in T_OldManagers
**          01/28/2020 mem - Fix bug warning of unknown managers
**          01/31/2023 mem - Use new view name
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @mgrList varchar(max),    -- One or more manager names (comma-separated list); supports wildcards because uses stored procedure parse_manager_name_list
    @infoOnly tinyint = 1,
    @message varchar(512)='' output
)
AS
    Set XACT_ABORT, NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------
    --
    Set @MgrList = IsNull(@MgrList, '')
    Set @InfoOnly = IsNull(@InfoOnly, 1)
    Set @message = ''

    CREATE TABLE #TmpManagerList (
        Manager_Name varchar(50) NOT NULL,
        M_ID int NULL,
        M_ControlFromWebsite tinyint null
    )

    ---------------------------------------------------
    -- Populate #TmpManagerList with the managers in @MgrList
    ---------------------------------------------------
    --

    exec parse_manager_name_list @MgrList, @RemoveUnknownManagers=0

    If Not Exists (Select * from #TmpManagerList)
    Begin
        Set @message = '@MgrList was empty; no match in T_Mgrs to ' + @MgrList
        Select @Message as Warning
        Goto done
    End

    ---------------------------------------------------
    -- Validate the manager names
    ---------------------------------------------------
    --
    UPDATE #TmpManagerList
    SET M_ID = M.M_ID,
        M_ControlFromWebsite = M.M_ControlFromWebsite
    FROM #TmpManagerList Target
         INNER JOIN T_Mgrs M
           ON Target.Manager_Name = M.M_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Exists (Select * from #TmpManagerList WHERE M_ID Is Null)
    Begin
        SELECT 'Unknown manager (not in T_Mgrs)' AS Warning, Manager_Name
        FROM #TmpManagerList
        WHERE M_ID Is Null
        ORDER BY Manager_Name
    End

    If Exists (Select * from #TmpManagerList WHERE NOT M_ID is Null And M_ControlFromWebsite > 0)
    Begin
        SELECT 'Manager has M_ControlFromWebsite=1; cannot archive' AS Warning,
               Manager_Name
        FROM #TmpManagerList
        WHERE NOT M_ID IS NULL AND
              M_ControlFromWebsite > 0
        ORDER BY Manager_Name
    End

    If Exists (Select * From #TmpManagerList Where Manager_Name Like '%Params%')
    Begin
        SELECT 'Will not process managers with "Params" in the name (for safety)' AS Warning,
               Manager_Name
        FROM #TmpManagerList
        WHERE Manager_Name Like '%Params%'
        ORDER BY Manager_Name

        DELETE From #TmpManagerList Where Manager_Name Like '%Params%'
    End

    If @InfoOnly <> 0
    Begin
        SELECT Src.manager_name,
               Src.m_controlfromwebsite As control_from_website,
               PV.mgr_type_id,
               PV.param_name,
               PV.entry_id,
               PV.param_type_id,
               PV.value,
               PV.mgr_id,
               PV.comment,
               PV.last_affected,
               PV.entered_by
        FROM #TmpManagerList Src
             LEFT OUTER JOIN V_Param_Value PV
               ON PV.mgr_id = Src.M_ID
        ORDER BY Src.Manager_Name, Param_Name

    End
    Else
    Begin
        DELETE FROM #TmpManagerList WHERE M_ID is Null OR M_ControlFromWebsite > 0

        Declare @MoveParams varchar(24) = 'Move params transaction'
        Begin Tran @MoveParams


        INSERT INTO T_OldManagers( M_ID,
                                   M_Name,
                                   M_TypeID,
                                   M_ParmValueChanged,
                                   M_ControlFromWebsite,
                                   M_Comment )
        SELECT M.M_ID,
               M.M_Name,
               M.M_TypeID,
               M.M_ParmValueChanged,
               M.M_ControlFromWebsite,
               M.M_Comment
        FROM T_Mgrs M
             INNER JOIN #TmpManagerList Src
               ON M.M_ID = Src.M_ID
          LEFT OUTER JOIN T_OldManagers Target
               ON Src.M_ID = Target.M_ID
        WHERE Target.M_ID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Rollback
            Select 'Aborted (rollback)' as Warning, @myError as ErrorCode
            Goto Done
        End


        INSERT INTO T_ParamValue_OldManagers(
                 Entry_ID,
                 TypeID,
                 [Value],
                 MgrID,
                 [Comment],
                 Last_Affected,
                 Entered_By )
        SELECT PV.Entry_ID,
               PV.TypeID,
               PV.[Value],
               PV.MgrID,
               PV.[Comment],
               PV.Last_Affected,
               PV.Entered_By
        FROM T_ParamValue PV
             INNER JOIN #TmpManagerList Src
               ON PV.MgrID = Src.M_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Rollback
            Select 'Aborted (rollback)' as Warning, @myError as ErrorCode
            Goto Done
        End

        DELETE T_ParamValue
        FROM T_ParamValue PV
             INNER JOIN #TmpManagerList Src
               ON PV.MgrID = Src.M_ID

        DELETE T_Mgrs
        FROM T_Mgrs M
             INNER JOIN #TmpManagerList Src
               ON M.M_ID = Src.M_ID

        Commit Tran @MoveParams

        SELECT 'Moved to T_OldManagers and T_ParamValue_OldManagers' as Message,
               Src.Manager_Name,
               Src.M_ControlFromWebsite,
               PT.ParamName,
               PV.Entry_ID,
               PV.TypeID,
               PV.[Value],
               PV.MgrID,
               PV.[Comment],
               PV.Last_Affected,
               PV.Entered_By
        FROM #TmpManagerList Src
             LEFT OUTER JOIN T_ParamValue_OldManagers PV
               ON PV.MgrID = Src.M_ID
             LEFT OUTER JOIN T_ParamType PT ON
             PV.TypeID = PT.ParamID
        ORDER BY Src.Manager_Name, ParamName
    End


Done:
    RETURN @myError

GO
