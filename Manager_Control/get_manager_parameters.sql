/****** Object:  StoredProcedure [dbo].[get_manager_parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_manager_parameters]
/****************************************************
**
**  Desc:   Gets the parameters for the given analysis manager(s)
**          Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/07/2015 mem - Initial version
**          08/10/2015 mem - Add @SortMode=3
**          09/02/2016 mem - Increase the default for parameter @MaxRecursion from 5 to 50
**          03/14/2018 mem - Refactor actual parameter lookup into stored procedure get_manager_parameters_work
**          01/31/2023 mem - Rename columns in #Tmp_Mgr_Params
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerNameList varchar(4000) = '',
    @sortMode tinyint = 0,                    -- 0 means sort by ParamTypeID then MgrName, 1 means ParamName, then MgrName, 2 means MgrName, then ParamName, 3 means Value then ParamName
    @maxRecursion tinyint = 50,
    @message varchar(512) = '' output
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    -----------------------------------------------
    -- Validate the inputs
    -----------------------------------------------
    --
    Set @ManagerNameList = IsNull(@ManagerNameList, '')

    Set @SortMode = IsNull(@SortMode, 0)

    If @MaxRecursion > 10
        Set @MaxRecursion = 10

    -----------------------------------------------
    -- Create the Temp Table to hold the manager parameters
    -----------------------------------------------

    CREATE TABLE #Tmp_Mgr_Params (
        mgr_name varchar(50) NOT NULL,
        param_name varchar(50) NOT NULL,
        entry_id int NOT NULL,
        param_type_id int NOT NULL,
        value varchar(128) NOT NULL,
        mgr_id int NOT NULL,
        comment varchar(255) NULL,
        last_affected datetime NULL,
        entered_by varchar(128) NULL,
        mgr_type_id int NOT NULL,
        parent_param_pointer_state tinyint,
        source varchar(50) NOT NULL
    )

    -- Populate the temporary table with the manager parameters
    Exec @myError = get_manager_parameters_work @ManagerNameList, @SortMode, @MaxRecursion, @message = @message Output

    -- Return the parameters as a result set

    If @SortMode = 0
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY param_type_id, mgr_name

    If @SortMode = 1
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY param_name, mgr_name

    If @SortMode = 2
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY mgr_name, param_name

    If @SortMode Not In (0,1,2)
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY value, param_name

     Drop Table #Tmp_Mgr_Params

Done:
    Return @myError

GO
GRANT EXECUTE ON [dbo].[get_manager_parameters] TO [DMSReader] AS [dbo]
GO
