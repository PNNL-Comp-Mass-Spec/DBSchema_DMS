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
           Value,
           MgrID,
           Comment,
           Last_Affected,
           Entered_By,
           M_TypeID,
           CASE
               WHEN TypeID = 162 THEN 1        -- ParamName 'Default_AnalysisMgr_Params'
               ELSE 0
           End As ParentParamPointerState,
           M_Name
    FROM V_ParamValue
    WHERE (M_Name IN (Select Value From dbo.udfParseDelimitedList(@ManagerNameList, ',')))
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
        SELECT ValuesToAppend.M_Name,
               ValuesToAppend.ParamName,
               ValuesToAppend.Entry_ID,
               ValuesToAppend.TypeID,
               ValuesToAppend.Value,
               ValuesToAppend.MgrID,
               ValuesToAppend.Comment,
               ValuesToAppend.Last_Affected,
               ValuesToAppend.Entered_By,
               ValuesToAppend.M_TypeID,
               CASE
                   WHEN ValuesToAppend.TypeID = 162 THEN 1
                   ELSE 0
               End As ParentParamPointerState,
               ValuesToAppend.Source
        FROM #Tmp_Mgr_Params Target
             RIGHT OUTER JOIN ( SELECT FilterQ.M_Name,
                                       PV.ParamName,
                                       PV.Entry_ID,
                                       PV.TypeID,
                                       PV.Value,
                                       PV.MgrID,
                                       PV.Comment,
                                       PV.Last_Affected,
                                       PV.Entered_By,
                                       PV.M_TypeID,
                                       PV.M_Name AS Source
                                FROM V_ParamValue PV
                                     INNER JOIN ( SELECT M_Name,
                                                         Group_Name
                                                  FROM #Tmp_Manager_Group_Info ) FilterQ
                                       ON PV.M_Name = FilterQ.Group_Name ) ValuesToAppend
               ON Target.M_Name = ValuesToAppend.M_Name AND
                  Target.TypeID = ValuesToAppend.TypeID
        WHERE (Target.TypeID IS NULL Or ValuesToAppend.typeID = 162)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- This is a safety check in case a manager has a Default_AnalysisMgr_Params value pointing to itself
        Set @iterations = @iterations + 1
        
    End
    
    Drop Table #Tmp_Manager_Group_Info

Done:
    Return @myError


GO
