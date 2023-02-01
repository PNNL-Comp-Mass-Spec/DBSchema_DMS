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
**  Auth:   mem
**  Date:   03/14/2018 mem - Initial version (code refactored from GetManagerParameters)
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
    
    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

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

    INSERT INTO #Tmp_Mgr_Params( M_Name,
                                 ParamName,
                                 Entry_ID,
                                 TypeID,
                                 Value,
                                 MgrID,
                                 Comment,
                                 Last_Affected,
                                 Entered_By,
                                 M_TypeID,
                                 ParentParamPointerState,
                                 Source )
    SELECT M_Name,
           ParamName,
           Entry_ID,
           TypeID,
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
    
    While Exists (Select * from #Tmp_Mgr_Params Where ParentParamPointerState = 1) And @iterations < @MaxRecursion
    Begin
        Truncate table #Tmp_Manager_Group_Info
        
        INSERT INTO #Tmp_Manager_Group_Info (M_Name, Group_Name)
        SELECT M_Name, Value
        FROM #Tmp_Mgr_Params
        WHERE (ParentParamPointerState = 1)
         
        UPDATE #Tmp_Mgr_Params
        Set ParentParamPointerState = 2
        WHERE (ParentParamPointerState = 1)

        INSERT INTO #Tmp_Mgr_Params( M_Name,
                                     ParamName,
                                     Entry_ID,
                                     TypeID,
                                     Value,
                                     MgrID,
                                     Comment,
                                     Last_Affected,
                                     Entered_By,
                                     M_TypeID,
                                     ParentParamPointerState,
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
