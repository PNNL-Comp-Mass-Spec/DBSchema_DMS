/****** Object:  StoredProcedure [dbo].[unarchive_old_managers_and_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[unarchive_old_managers_and_params]
/****************************************************
**
**  Desc:   Moves managers from T_OldManagers to T_Mgrs
**          and moves manager parameters from T_ParamValue_OldManagers to T_ParamValue
**
**          To reverse this process, use procedure archive_old_managers_and_params
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   02/25/2016 mem - Initial version
**          04/22/2016 mem - Now updating M_Comment in T_Mgrs
**          01/31/2023 mem - Use new view name
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @mgrList varchar(max),    -- One or more manager names (comma-separated list); supports wildcards because uses stored procedure parse_manager_name_list
    @infoOnly tinyint = 1,
    @enableControlFromWebsite tinyint = 0,
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
    Set @EnableControlFromWebsite = IsNull(@EnableControlFromWebsite, 1)
    Set @message = ''

    If @EnableControlFromWebsite > 0
        Set @EnableControlFromWebsite= 1

    CREATE TABLE #TmpManagerList (
        Manager_Name varchar(50) NOT NULL,
        M_ID int NULL
    )

    ---------------------------------------------------
    -- Populate #TmpManagerList with the managers in @MgrList
    ---------------------------------------------------
    --

    exec parse_manager_name_list @MgrList, @RemoveUnknownManagers=0

    If Not Exists (Select * from #TmpManagerList)
    Begin
        Set @message = '@MgrList was empty'
        Select @Message as Warning
        Goto done
    End

    ---------------------------------------------------
    -- Validate the manager names
    ---------------------------------------------------
    --
    UPDATE #TmpManagerList
    SET M_ID = M.M_ID
    FROM #TmpManagerList Target
         INNER JOIN T_OldManagers M
           ON Target.Manager_Name = M.M_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Exists (Select * from #TmpManagerList where M_ID Is Null)
    Begin
        SELECT 'Unknown manager (not in T_OldManagers)' AS Warning, Manager_Name
        FROM #TmpManagerList
        WHERE M_ID  Is Null
        ORDER BY Manager_Name
    End

    If Exists (Select * From #TmpManagerList Where Manager_Name Like '%Params%')
    Begin
        SELECT 'Will not process managers with "Params" in the name (for safety)' AS Warning,
               Manager_Name
        FROM #TmpManagerList
        WHERE Manager_Name Like '%Params%'
        ORDER BY Manager_Name
        --
        DELETE From #TmpManagerList Where Manager_Name Like '%Params%'
    End

    If Exists (Select * FROM #TmpManagerList Where Manager_Name IN (Select M_Name From T_Mgrs))
    Begin
        SELECT DISTINCT 'Will not process managers with existing entries in T_Mgrs' AS Warning,
                        Manager_Name
        FROM #TmpManagerList Src
        WHERE Manager_Name IN (Select M_Name From T_Mgrs)
        ORDER BY Manager_Name
        --
        DELETE From #TmpManagerList Where Manager_Name IN (Select M_Name From T_Mgrs)
    End

    If Exists (Select * FROM #TmpManagerList Where M_ID IN (Select Distinct MgrID From T_ParamValue))
    Begin
        SELECT DISTINCT 'Will not process managers with existing entries in T_ParamValue' AS Warning,
                        Manager_Name
        FROM #TmpManagerList Src
        WHERE M_ID IN (Select Distinct MgrID From T_ParamValue)
        ORDER BY Manager_Name

        DELETE From #TmpManagerList Where M_ID IN (Select Distinct MgrID From T_ParamValue)
    End

    If @InfoOnly <> 0
    Begin
        SELECT Src.manager_name,
               @EnableControlFromWebsite AS control_from_website,
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
             LEFT OUTER JOIN V_Old_Param_Value PV
               ON PV.Mgr_ID = Src.M_ID
        ORDER BY Src.Manager_Name, Param_Name

    End
    Else
    Begin
        DELETE FROM #TmpManagerList WHERE M_ID is Null

        Declare @MoveParams varchar(24) = 'Move params transaction'
        Begin Tran @MoveParams

        SET IDENTITY_INSERT T_Mgrs ON

        INSERT INTO T_Mgrs ( M_ID,
                             M_Name,
                             M_TypeID,
                             M_ParmValueChanged,
                             M_ControlFromWebsite,
                             M_Comment )
        SELECT M.M_ID,
               M.M_Name,
               M.M_TypeID,
               M.M_ParmValueChanged,
               @EnableControlFromWebsite,
               M.M_Comment
        FROM T_OldManagers M
             INNER JOIN #TmpManagerList Src
               ON M.M_ID = Src.M_ID
          LEFT OUTER JOIN T_Mgrs Target
           ON Src.M_ID = Target.M_ID
        WHERE Target.M_ID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        SET IDENTITY_INSERT T_Mgrs Off
        --
        If @myError <> 0
        Begin
            Rollback
            Select 'Aborted (rollback) due to insert error for T_Mgrs' as Warning, @myError as ErrorCode
            Goto Done
        End

        SET IDENTITY_INSERT T_ParamValue On

        INSERT INTO T_ParamValue (
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
        FROM T_ParamValue_OldManagers PV
             INNER JOIN #TmpManagerList Src
               ON PV.MgrID = Src.M_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        SET IDENTITY_INSERT T_ParamValue On
        --
        If @myError <> 0
        Begin
            Rollback
            Select 'Aborted (rollback) due to insert error for T_ParamValue_OldManagers' as Warning, @myError as ErrorCode
            Goto Done
        End

        DELETE T_ParamValue_OldManagers
        FROM T_ParamValue_OldManagers PV
             INNER JOIN #TmpManagerList Src
               ON PV.MgrID = Src.M_ID

        DELETE T_OldManagers
        FROM T_OldManagers M
             INNER JOIN #TmpManagerList Src
               ON M.M_ID = Src.M_ID

        Commit Tran @MoveParams

        SELECT 'Moved to T_Managers and T_ParamValue' as Message,
               Src.Manager_Name,
               @EnableControlFromWebsite AS M_ControlFromWebsite,
               PT.ParamName,
               PV.Entry_ID,
               PV.TypeID,
               PV.[Value],
               PV.MgrID,
               PV.[Comment],
               PV.Last_Affected,
               PV.Entered_By
        FROM #TmpManagerList Src
             LEFT OUTER JOIN T_ParamValue PV
               ON PV.MgrID = Src.M_ID
             LEFT OUTER JOIN T_ParamType PT
               On PV.TypeID = PT.ParamID
        ORDER BY Src.Manager_Name, ParamName
    End


Done:
    RETURN @myError

GO
