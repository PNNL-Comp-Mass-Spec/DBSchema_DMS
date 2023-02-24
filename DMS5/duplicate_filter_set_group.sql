/****** Object:  StoredProcedure [dbo].[DuplicateFilterSetGroup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DuplicateFilterSetGroup]
/****************************************************
**
**  Desc:
**      Copies a given group for a given filter set
**      This procedure will auto-create a new entry in T_Filter_Set_Criteria_Groups
**      For safety, requires that you provide both the filter set ID and the Group ID to copy
**
**  Auth:   mem
**  Date:   02/17/2009
**
*****************************************************/
(
    @FilterSetID int,
    @FilterCriteriaGroupID int,
    @InfoOnly tinyint = 0,
    @message varchar(512)='' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    Declare @TranAddGroup varchar(64)
    Declare @FilterCriteriaGroupIDNext int

    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------

    Set @InfoOnly = IsNull(@InfoOnly, 0)
    Set @message = ''

    If @FilterSetID Is Null Or @FilterCriteriaGroupID Is Null
    Begin
        Set @message = 'Both the filter set ID and the filter criteria group ID must be defined; unable to continue'
        Set @myError = 53000
        Goto Done
    End

    -----------------------------------------
    -- Validate that @FilterSetID is defined in T_Filter_Sets
    -----------------------------------------
    --
    if Not Exists (SELECT * FROM T_Filter_Sets WHERE Filter_Set_ID = @FilterSetID)
    Begin
        Set @message = 'Filter Set ID ' + Convert(varchar(11), @FilterSetID) + ' was not found in T_Filter_Sets; unable to continue'
        Goto Done
    End

    -----------------------------------------
    -- Validate that @FilterCriteriaGroupID is defined in T_Filter_Set_Criteria_Groups
    -----------------------------------------
    --
    if Not Exists (SELECT * FROM T_Filter_Set_Criteria_Groups WHERE Filter_Criteria_Group_ID = @FilterCriteriaGroupID)
    Begin
        Set @message = 'Filter Criteria Group ID ' + Convert(varchar(11), @FilterCriteriaGroupID) + ' was not found in T_Filter_Set_Criteria_Groups; unable to continue'
        Goto Done
    End

    -----------------------------------------
    -- Make sure that @FilterCriteriaGroupID is mapped to @FilterSetID
    -----------------------------------------
    --
    if Not Exists (SELECT * FROM T_Filter_Set_Criteria_Groups WHERE Filter_Criteria_Group_ID = @FilterCriteriaGroupID AND Filter_Set_ID = @FilterSetID)
    Begin
        Set @message = 'Filter Criteria Group ID ' + Convert(varchar(11), @FilterCriteriaGroupID) + ' is not mapped to Filter Set ID ' + Convert(varchar(11), @FilterSetID) + ' in T_Filter_Set_Criteria_Groups; unable to continue'
        Goto Done
    End

    Set @TranAddGroup = 'Add Group Transaction'
    Begin Tran @TranAddGroup

    -----------------------------------------
    -- Lookup the next available Filter Criteria Group ID
    -----------------------------------------
    --
    SELECT @FilterCriteriaGroupIDNext = MAX(Filter_Criteria_Group_ID) + 1
    FROM T_Filter_Set_Criteria_Groups

    If @InfoOnly <> 0
    Begin
        SELECT @FilterCriteriaGroupIDNext AS NewGroupID, Criterion_ID, Criterion_Comparison, Criterion_Value
        FROM dbo.T_Filter_Set_Criteria
        WHERE Filter_Criteria_Group_ID = @FilterCriteriaGroupID
        ORDER BY Criterion_ID
    End
    Else
    Begin

        -- Create a new entry in T_Filter_Set_Criteria_Groups

        INSERT INTO T_Filter_Set_Criteria_Groups (Filter_Set_ID, Filter_Criteria_Group_ID)
        VALUES (@FilterSetID, @FilterCriteriaGroupIDNext)
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If @myError <> 0
        Begin
            Set @message = 'Error inserting new filter criteria group ID into T_Filter_Set_Criteria_Groups'
            Rollback Tran @TranAddGroup
            Goto Done
        End

        -- Duplicate the criteria for group @FilterCriteriaGroupID (from Filter Set @FilterSetID)
        --
        INSERT INTO dbo.T_Filter_Set_Criteria
            (Filter_Criteria_Group_ID, Criterion_ID, Criterion_Comparison, Criterion_Value)
        SELECT @FilterCriteriaGroupIDNext AS NewGroupID, Criterion_ID, Criterion_Comparison, Criterion_Value
        FROM dbo.T_Filter_Set_Criteria
        WHERE Filter_Criteria_Group_ID = @FilterCriteriaGroupID
        ORDER BY Criterion_ID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

    End

    Commit Tran @TranAddGroup

    Set @message = 'Duplicated Filter Criteria Group ' + Convert(varchar(11), @FilterCriteriaGroupID) + ' for Filter Set ID ' + Convert(varchar(11), @FilterSetID)

Done:
    If Len(@message) > 0
        SELECT @message As Message

    --
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateFilterSetGroup] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DuplicateFilterSetGroup] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DuplicateFilterSetGroup] TO [PNL\D3M578] AS [dbo]
GO
