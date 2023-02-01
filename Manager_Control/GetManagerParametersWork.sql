/****** Object:  StoredProcedure [dbo].[GetManagerParametersWork] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetManagerParametersWork]
/****************************************************
**
**  Desc:   Populates temporary tables with the parameters for the given analysis manager(s)
**          Uses MgrSettingGroupName to lookup parameters from the parent group, if any
**
**  Requires that the calling procedure create temporary table #Tmp_Mgr_Params
**
**      CREATE TABLE #Tmp_Mgr_Params (
**          mgr_name varchar(50) NOT NULL,
**          param_name varchar(50) NOT NULL,
**          entry_id int NOT NULL,
**          param_type_id int NOT NULL,
**          value varchar(128) NOT NULL,
**          mgr_id int NOT NULL,
**          comment varchar(255) NULL,
**          last_affected datetime NULL,
**          entered_by varchar(128) NULL,
**          mgr_type_id int NOT NULL,
**          parent_param_pointer_state tinyint,
**          source varchar(50) NOT NULL
**      )
**
**  Auth:   mem
**  Date:   03/14/2018 mem - Initial version (code refactored from GetManagerParameters)
**          01/31/2023 mem - Use new view name
**
*****************************************************/
(
    @ManagerNameList varchar(4000) = '',
    @SortMode tinyint = 0,                    -- 0 means sort by ParamTypeID then MgrName, 1 means ParamName, then MgrName, 2 means MgrName, then ParamName, 3 means Value then ParamName
    @MaxRecursion tinyint = 50,
    @message varchar(512)='' output
)
As
    Set NoCount On

    Declare @myRowCount Int = 0
    Declare @myError Int = 0

    -----------------------------------------------
    -- Create the Temp Table to hold the manager group information
    -----------------------------------------------

    CREATE TABLE #Tmp_Manager_Group_Info (
        M_Name varchar(50) NOT NULL,
        Group_Name varchar(128) NOT NULL
    )

    -----------------------------------------------
    -- Lookup the initial manager parameters
    -----------------------------------------------
    --

    INSERT INTO #Tmp_Mgr_Params( mgr_name,
                                 param_name,
                                 entry_id,
                                 param_type_id,
                                 value,
                                 mgr_id,
                                 comment,
                                 last_affected,
                                 entered_by,
                                 mgr_type_id,
                                 parent_param_pointer_state,
                                 source )
    SELECT mgr_name,
           param_name,
           entry_id,
           param_type_id,
           Value,
           mgr_id,
           comment,
           last_affected,
           entered_by,
           mgr_type_id,
           CASE
               WHEN mgr_type_id = 162 THEN 1        -- ParamName 'Default_AnalysisMgr_Params'
               ELSE 0
           End As parent_param_pointer_state,
           mgr_name
    FROM V_Param_Value
    WHERE (mgr_name IN (Select Value From dbo.udfParseDelimitedList(@ManagerNameList, ',')))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    -----------------------------------------------
    -- Append parameters for parent groups, which are
    -- defined by parameter Default_AnalysisMgr_Params (TypeID 162)
    -----------------------------------------------
    --
    Declare @iterations tinyint = 0

    While Exists (Select * from #Tmp_Mgr_Params Where parent_param_pointer_state = 1) And @iterations < @MaxRecursion
    Begin
        Truncate table #Tmp_Manager_Group_Info

        INSERT INTO #Tmp_Manager_Group_Info (M_Name, Group_Name)
        SELECT mgr_name, value
        FROM #Tmp_Mgr_Params
        WHERE parent_param_pointer_state = 1

        UPDATE #Tmp_Mgr_Params
        Set parent_param_pointer_state = 2
        WHERE parent_param_pointer_state = 1

        INSERT INTO #Tmp_Mgr_Params( mgr_name,
                                     param_name,
                                     Entry_ID,
                                     param_type_id,
                                     value,
                                     mgr_id,
                                     comment,
                                     last_affected,
                                     entered_by,
                                     mgr_type_id,
                                     parent_param_pointer_state,
                                     Source )
        SELECT ValuesToAppend.mgr_name,
               ValuesToAppend.param_name,
               ValuesToAppend.entry_id,
               ValuesToAppend.param_type_id,
               ValuesToAppend.value,
               ValuesToAppend.mgr_id,
               ValuesToAppend.comment,
               ValuesToAppend.last_affected,
               ValuesToAppend.entered_by,
               ValuesToAppend.mgr_type_id,
               CASE
                   WHEN ValuesToAppend.param_type_id = 162 THEN 1
                   ELSE 0
               End As ParentParamPointerState,
               ValuesToAppend.Source
        FROM #Tmp_Mgr_Params Target
             RIGHT OUTER JOIN ( SELECT FilterQ.M_Name as mgr_name,
                                       PV.param_name,
                                       PV.entry_id,
                                       PV.param_type_id,
                                       PV.value,
                                       PV.mgr_id,
                                       PV.comment,
                                       PV.last_affected,
                                       PV.entered_by,
                                       PV.mgr_type_id,
                                       PV.mgr_name AS Source
                                FROM V_Param_Value PV
                                     INNER JOIN ( SELECT M_Name,
                                                         Group_Name
                                                  FROM #Tmp_Manager_Group_Info ) FilterQ
                                       ON PV.mgr_name = FilterQ.Group_Name ) ValuesToAppend
               ON Target.mgr_name = ValuesToAppend.mgr_name AND
                  Target.param_type_id = ValuesToAppend.param_type_id
        WHERE (Target.param_type_id IS NULL Or ValuesToAppend.param_type_id = 162)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- This is a safety check in case a manager has a Default_AnalysisMgr_Params value pointing to itself
        Set @iterations = @iterations + 1

    End

    Drop Table #Tmp_Manager_Group_Info

Done:
    Return @myError


GO
