/****** Object:  StoredProcedure [dbo].[ParseManagerNameList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.ParseManagerNameList
/****************************************************
**
**  Desc:   Parses the list of managers in @ManagerNameList and populates
**          a temporary tables with the manager names
**
**          If @RemoveUnknownManagers = 1, then deletes manager names that are not defined in T_Mgrs
**
**          The calling procedure must create the following temporary table:
**          CREATE TABLE #TmpManagerList (
**              Manager_Name varchar(128) NOT NULL
**          )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/09/2008
**          05/14/2015 mem - Update Insert query to explicitly list field Manager_Name
**
*****************************************************/
(
    @ManagerNameList varchar(4000) = '',
    @RemoveUnknownManagers tinyint = 1,
    @message varchar(512)='' output
)
As
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    Declare @EntryID int
    Declare @Continue int

    Declare @ManagerFilter varchar(128)
    Declare @S varchar(4000)

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @ManagerNameList = IsNull(@ManagerNameList, '')
    Set @RemoveUnknownManagers = IsNull(@RemoveUnknownManagers, 1)
    Set @message = ''

    -----------------------------------------------
    -- Creata a temporary table
    -----------------------------------------------

    CREATE TABLE #TmpMangerSpecList (
        Entry_ID int Identity (1,1),
        Manager_Name varchar(128) NOT NULL
    )

    -----------------------------------------------
    -- Parse @ManagerNameList
    -----------------------------------------------

    If Len(@ManagerNameList) > 0
    Begin -- <a>

        -- Populate #TmpMangerSpecList with the data in @ManagerNameList
        INSERT INTO #TmpMangerSpecList (Manager_Name)
        SELECT Value
        FROM dbo.udfParseDelimitedList(@ManagerNameList, ',')
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        -- Populate #TmpManagerList with the entries in #TmpMangerSpecList that do not contain a % wildcard
        INSERT INTO #TmpManagerList (Manager_Name)
        SELECT Manager_Name
        FROM #TmpMangerSpecList
        WHERE NOT Manager_Name LIKE '%[%]%'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Delete the non-wildcard entries from #TmpMangerSpecList
        DELETE FROM #TmpMangerSpecList
        WHERE NOT Manager_Name LIKE '%[%]%'


        -- Parse the entries in #TmpMangerSpecList (all should have a wildcard)
        Set @EntryID = 0

        Set @Continue = 1
        While @Continue = 1
        Begin -- <b1>
            SELECT TOP 1 @EntryID = Entry_ID,
                         @ManagerFilter = Manager_Name
            FROM #TmpMangerSpecList
            WHERE Entry_ID > @EntryID
            ORDER BY Entry_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @Continue = 0
            Else
            Begin -- <c>
                Set @S = ''
                Set @S = @S + ' INSERT INTO #TmpManagerList (Manager_Name)'
                Set @S = @S + ' SELECT M_Name'
                Set @S = @S + ' FROM T_Mgrs'
                Set @S = @S + ' WHERE M_Name LIKE ''' + @ManagerFilter + ''''

                Exec (@S)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

            End -- </c>

        End -- </b1>

        If @RemoveUnknownManagers <> 0
        Begin -- <b2>
            -- Delete entries from #TmpManagerList that don't match entries in M_Name of the given type
            DELETE #TmpManagerList
            FROM #TmpManagerList U LEFT OUTER JOIN
                T_Mgrs M ON M.M_Name = U.Manager_Name
            WHERE M.M_Name Is Null
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount > 0
            Begin
                Set @message = 'Found ' + convert(varchar(12), @myRowCount) + ' entries in @ManagerNameList that are not defined in T_Mgrs'
                Print @message

                Set @message = ''
            End

        End -- </b2>

    End -- </a>

    Return @myError


GO
GRANT EXECUTE ON [dbo].[ParseManagerNameList] TO [Mgr_Config_Admin] AS [dbo]
GO
