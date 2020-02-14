/****** Object:  StoredProcedure [dbo].[GetManagerParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetManagerParameters]
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
**          03/14/2018 mem - Refactor actual parameter lookup into stored procedure GetManagerParametersWork
**    
*****************************************************/
(
    @ManagerNameList varchar(4000) = '',
    @SortMode tinyint = 0,                    -- 0 means sort by ParamTypeID then MgrName, 1 means ParamName, then MgrName, 2 means MgrName, then ParamName, 3 means Value then ParamName
    @MaxRecursion tinyint = 50,
    @message varchar(512) = '' output
)
As
    Set NoCount On
    
    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0
    
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
        M_Name varchar(50) NOT NULL,
        ParamName varchar(50) NOT NULL,
        Entry_ID int NOT NULL,
        TypeID int NOT NULL,
        Value varchar(128) NOT NULL,
        MgrID int NOT NULL,
        Comment varchar(255) NULL,
        Last_Affected datetime NULL,
        Entered_By varchar(128) NULL,
        M_TypeID int NOT NULL,
        ParentParamPointerState tinyint,
        Source varchar(50) NOT NULL
    ) 

    -- Populate the temporary table with the manager parameters
    Exec @myError = GetManagerParametersWork @ManagerNameList, @SortMode, @MaxRecursion, @message = @message Output

    -- Return the parameters as a result set

    If @SortMode = 0
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY TypeID, M_Name
    
    If @SortMode = 1
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY ParamName, M_Name

    If @SortMode = 2
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY M_Name, ParamName

    If @SortMode Not In (0,1,2)
        SELECT *
        FROM #Tmp_Mgr_Params
        ORDER BY Value, ParamName

     Drop Table #Tmp_Mgr_Params

Done:
    Return @myError


GO
GRANT EXECUTE ON [dbo].[GetManagerParameters] TO [DMSReader] AS [dbo]
GO
