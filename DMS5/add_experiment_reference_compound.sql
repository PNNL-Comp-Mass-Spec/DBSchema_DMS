/****** Object:  StoredProcedure [dbo].[add_experiment_reference_compound] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_experiment_reference_compound]
/****************************************************
**
**  Desc: Adds reference compound entries to DB for given experiment
**
**  The calling procedure must create and populate temporary table #Tmp_ExpToRefCompoundMap:
**
**      CREATE TABLE #Tmp_ExpToRefCompoundMap (
**          Compound_IDName varchar(128) not null,
**          Colon_Pos int null,
**          Compound_ID int null
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/29/2017 mem - Initial version
**          01/04/2018 mem - Update fields in #Tmp_ExpToRefCompoundMap, switching from Compound_Name to Compound_IDName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @experimentID int,
    @updateCachedInfo tinyint = 1,
    @message varchar(255) = '' output
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)
    Declare @invalidRefCompoundList varchar(512)

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If @experimentID Is Null
    Begin
        set @message = 'Experiment ID cannot be null'
        return 51061
    End

    Set @updateCachedInfo = IsNull(@updateCachedInfo, 1)
    Set @message = ''

    ---------------------------------------------------
    -- Try to resolve any null reference compound ID values in #Tmp_ExpToRefCompoundMap
    ---------------------------------------------------
    --
    -- Make sure column Colon_Pos is populated
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Colon_Pos = CharIndex(':', Compound_IDName)
    WHERE Colon_Pos Is Null

    -- Update entries in #Tmp_ExpToRefCompoundMap to remove extra text that may be present
    -- For example, switch from 3311:ANFTSQETQGAGK to 3311
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Compound_IDName = Substring(Compound_IDName, 1, Colon_Pos - 1)
    WHERE Not Colon_Pos Is Null And Colon_Pos > 0 AND Compound_IDName Like '%:%'

    -- Populate the Compound_ID column using any integers in Compound_IDName
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Compound_ID = Try_Cast(Compound_IDName as Int)
    WHERE Compound_ID Is Null

    -- If any entries still have a null Compound_ID value, try matching via reference compound name
    -- We have numerous reference compounds with identical names, so matches found this way will be ambiguous
    --
    UPDATE #Tmp_ExpToRefCompoundMap
    SET Compound_ID = Src.Compound_ID
    FROM #Tmp_ExpToRefCompoundMap Target
         INNER JOIN T_Reference_Compound Src
           ON Src.Compound_Name = Target.Compound_IDName
    WHERE Target.Compound_ID IS Null
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Look for invalid entries in #Tmp_ExpToRefCompoundMap
    ---------------------------------------------------
    --

    -- First look for entries without a Compound_ID
    --
    Set @invalidRefCompoundList = null

    SELECT @invalidRefCompoundList = Coalesce(@invalidRefCompoundList + ', ' + Compound_IDName, Compound_IDName)
    FROM #Tmp_ExpToRefCompoundMap
    WHERE Compound_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Len(IsNull(@invalidRefCompoundList, '')) > 0
    Begin
        Set @message = 'Invalid reference compound name(s): ' + @invalidRefCompoundList
        return 51063
    End

    -- Next look for entries with an invalid Compound_ID
    --
    Set @invalidRefCompoundList = null

    SELECT @invalidRefCompoundList = Coalesce(@invalidRefCompoundList + ', ' + Compound_IDName, Compound_IDName)
    FROM #Tmp_ExpToRefCompoundMap Src
         LEFT OUTER JOIN T_Reference_Compound RC
           ON Src.Compound_ID = RC.Compound_ID
    WHERE NOT Src.Compound_ID IS NULL AND
          RC.Compound_ID IS NULL
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If Len(IsNull(@invalidRefCompoundList, '')) > 0
    Begin
        Set @message = 'Invalid reference compound ID(s): ' + @invalidRefCompoundList
        return 51063
    End

    ---------------------------------------------------
    -- Add/remove reference compounds
    ---------------------------------------------------
    --
    DELETE T_Experiment_Reference_Compounds
    WHERE Exp_ID = @experimentID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    INSERT INTO T_Experiment_Reference_Compounds (Exp_ID, Compound_ID)
    SELECT DISTINCT @experimentID as Exp_ID, Compound_ID
    FROM #Tmp_ExpToRefCompoundMap
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error updating reference compound mapping for experiment ' + Cast(@experimentID as varchar(9))
        return 51062
    end

    ---------------------------------------------------
    -- Optionally update T_Cached_Experiment_Components
    ---------------------------------------------------
    --
    If @updateCachedInfo > 0
    Begin
        Exec update_cached_experiment_component_names @experimentID
    End

    return 0

GO
