/****** Object:  StoredProcedure [dbo].[EnableDisableRunJobsRemotely] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[EnableDisableRunJobsRemotely]
/****************************************************
** 
**  Desc:   Enables or disables a manager to run jobs remotely
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/28/2018 mem - Initial version
**    
*****************************************************/
(
    @Enable tinyint,                        -- 0 to disable running jobs remotely, 1 to enable running jobs remotely
    @ManagerNameList varchar(4000) = '',    -- Manager(s) to update; supports % for wildcards
    @PreviewUpdates tinyint = 0,
    @message varchar(512) = '' output
)
As
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
    Set @ManagerNameList = IsNull(@ManagerNameList, '')
    Set @PreviewUpdates = IsNull(@PreviewUpdates, 0)

    If @Enable Is Null
    Begin
        set @myError  = 40000
        Set @message = '@Enable cannot be null'
        SELECT @message AS Message
        Goto Done
    End

    If Len(@ManagerNameList) = 0
    Begin
        set @myError  = 40003
        Set @message = '@ManagerNameList cannot be blank'
        SELECT @message AS Message
        Goto Done
    End

    -----------------------------------------------
    -- Creata a temporary table
    -----------------------------------------------

    CREATE TABLE #TmpManagerList (
        Manager_Name varchar(128) NOT NULL
    )
    
    -- Populate #TmpMangerList using ParseManagerNameList
    --    
    Exec @myError = ParseManagerNameList @ManagerNameList, @RemoveUnknownManagers=1, @message=@message output
    
    If @myError <> 0
    Begin
        If Len(@message) = 0
            Set @message = 'Error calling ParseManagerNameList: ' + Convert(varchar(12), @myError)
                
        Goto Done
    End
    
    -- Set @NewValue based on @Enable
    If @Enable = 0
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
            Set @message = 'No managers were found matching @ManagerNameList'
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
        If @PreviewUpdates <> 0
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
