/****** Object:  StoredProcedure [dbo].[EnableDisableAllManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[EnableDisableAllManagers]
/****************************************************
**
**  Desc:   Enables or disables all managers, optionally filtering by manager type ID or manager name
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/09/2008
**          06/09/2011 - Created by extending code in DisableAllManagers
**                     - Now filtering on MT_Active > 0 in T_MgrTypes
**          02/12/2020 mem - Rename parameter to @infoOnly
**
*****************************************************/
(
    @ManagerTypeIDList varchar(1024) = '',  -- Optional: list of manager type IDs to disable, e.g. "1, 2, 3"
    @ManagerNameList varchar(4000) = '',    -- Optional: if defined, then only managers specified here will be enabled; supports the % wildcard
    @Enable tinyint = 1,                    -- 1 to enable, 0 to disable
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
As
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    Declare @MgrTypeID int
    Declare @Continue int

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @Enable = IsNull(@Enable, 0)
    Set @ManagerTypeIDList = IsNull(@ManagerTypeIDList, '')
    Set @ManagerNameList = IsNull(@ManagerNameList, '')
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @message = ''

    CREATE TABLE #TmpManagerTypeIDs (
        MgrTypeID int NOT NULL
    )

    If Len(@ManagerTypeIDList) > 0
    Begin
        -- Parse @ManagerTypeIDList
        --
        INSERT INTO #TmpManagerTypeIDs (MgrTypeID)
        SELECT DISTINCT Value
        FROM dbo.udfParseDelimitedIntegerList(@ManagerTypeIDList, ',')
        ORDER BY Value
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        -- Populate #TmpManagerTypeIDs with all manager types in T_MgrTypes
        --
        INSERT INTO #TmpManagerTypeIDs (MgrTypeID)
        SELECT DISTINCT MT_TypeID
        FROM T_MgrTypes
        WHERE MT_Active > 0
        ORDER BY MT_TypeID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    -----------------------------------------------
    -- Loop through the manager types in #TmpManagerTypeIDs
    -- For each, call EnableDisableManagers
    -----------------------------------------------

    Set @MgrTypeID = 0
    SELECT @MgrTypeID = MIN(MgrTypeID)-1
    FROM #TmpManagerTypeIDs
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Set @Continue = 1
    While @Continue = 1
    Begin
        SELECT TOP 1 @MgrTypeID = MgrTypeID
        FROM #TmpManagerTypeIDs
        WHERE MgrTypeID > @MgrTypeID
        ORDER BY MgrTypeID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @Continue = 0
        Else
        Begin
            exec @myError = EnableDisableManagers @Enable=@Enable, @ManagerTypeID=@MgrTypeID, @ManagerNameList=@ManagerNameList, @infoOnly = @infoOnly, @message = @message output
        End
    End

Done:
    Return @myError


GO
GRANT EXECUTE ON [dbo].[EnableDisableAllManagers] TO [Mgr_Config_Admin] AS [dbo]
GO
