/****** Object:  StoredProcedure [dbo].[PopulateParamFileInfoTableSequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PopulateParamFileInfoTableSequest]
/****************************************************
**
**  Desc:
**      Updates #TmpParamFileInfo to include some additional Sequest-specific columns.
**
**      Returns the list of columns added using parameter @ParamFileInfoColumnList
**
**  Return values: 0: success, otherwise, error code
**
**  Date:   12/08/2006 mem - Initial version (Ticket #342)
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**
*****************************************************/
(
    @ParamFileInfoColumnList varchar(512)='' output,
    @message varchar(512) = '' output
)
As
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    Declare @continue tinyint
    Declare @UniqueID int

    Declare @TargetDataType varchar(64)
    Declare @TargetColumn varchar(128)

    Declare @S varchar(1024)

    -----------------------------------------------------------
    -- Append the new columns to #TmpParamFileInfo
    -----------------------------------------------------------

    ALTER TABLE #TmpParamFileInfo ADD
        Fragment_Ion_Tolerance real NULL DEFAULT (0) WITH VALUES,
        Enzyme varchar(64) NULL DEFAULT ('') WITH VALUES,
        Max_Missed_Cleavages int NULL DEFAULT (4) WITH VALUES,
        Parent_Mass_Type varchar(128) NULL DEFAULT ('Avg') WITH VALUES
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error appending the new columns to #TmpParamFileInfo: ' + Convert(varchar(19), @myError)
        Goto Done
    End

    Set @ParamFileInfoColumnList = 'Fragment_Ion_Tolerance, Enzyme, Max_Missed_Cleavages, Parent_Mass_Type'

    -----------------------------------------------------------
    -- Create and populate a table to track the columns
    --  to populate in #TmpParamFileInfo
    -----------------------------------------------------------
    CREATE TABLE #TmpParamEntryInfo (
        UniqueID int Identity(1,1),
        Entry_Type varchar(128),
        Entry_Specifier varchar(128),
        TargetDataType varchar(64),
        TargetColumn varchar(128)
    )

    INSERT INTO #TmpParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('AdvancedParam', 'FragmentIonTolerance', 'real', 'Fragment_Ion_Tolerance')

    INSERT INTO #TmpParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'SelectedEnzymeIndex', 'varchar(64)', 'Enzyme')

    INSERT INTO #TmpParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'MaximumNumberMissedCleavages', 'int', 'Max_Missed_Cleavages')

    INSERT INTO #TmpParamEntryInfo (Entry_Type, Entry_Specifier, TargetDataType, TargetColumn)
    VALUES ('BasicParam', 'ParentMassType', 'varchar(128)', 'Parent_Mass_Type')


    -----------------------------------------------------------
    -- Populate the new columns in #TmpParamFileInfo
    -- We have to use dynamic Sql here since the columns
    --  were added dynamically to #TmpParamFileInfo
    -----------------------------------------------------------

    Set @UniqueID = 0
    Set @continue = 1
    While @continue = 1
    Begin
        SELECT TOP 1 @UniqueID = UniqueID,
                     @TargetDataType = TargetDataType,
                     @TargetColumn = TargetColumn
        FROM #TmpParamEntryInfo
        WHERE UniqueID > @UniqueID
        ORDER BY UniqueID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
            Set @continue = 0
        Else
        Begin
            Set @S = ''
            Set @S = @S + ' UPDATE #TmpParamFileInfo'
            Set @S = @S + ' SET ' + @TargetColumn + ' = Convert(' + @TargetDataType + ', PE.Entry_Value)'
            Set @S = @S + ' FROM T_Param_Entries PE INNER JOIN'
            Set @S = @S +      ' #TmpParamEntryInfo PEI ON PE.Entry_Type = PEI.Entry_Type AND'
            Set @S = @S +      ' PE.Entry_Specifier = PEI.Entry_Specifier INNER JOIN'
            Set @S = @S +      ' #TmpParamFileInfo PFI ON PE.Param_File_ID = PFI.Param_File_ID'
            Set @S = @S + ' WHERE PEI.UniqueID = ' + Convert(varchar(12), @UniqueID)

            Exec (@S)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @message = 'Error updating the "' + @TargetColumn + '" column in #TmpParamFileInfo: ' + Convert(varchar(19), @myError)
                Goto Done
            End
        End

    End

    -----------------------------------------------------------
    -- Convert Enzyme from a number to a name
    -----------------------------------------------------------
    --
    UPDATE #TmpParamFileInfo
    SET Enzyme = IsNull(Enz.Enzyme_Name, PFI.Enzyme)
    FROM #TmpParamFileInfo PFI
         INNER JOIN ( SELECT Param_File_ID
                      FROM #TmpParamFileInfo
                      WHERE NOT Try_Convert(int, IsNull(Enzyme, '')) IS NULL
                    ) UpdateListQ
           ON PFI.Param_File_ID = UpdateListQ.Param_File_ID
         LEFT OUTER JOIN T_Enzymes Enz
           ON Convert(int, PFI.Enzyme) = Enz.Sequest_Enzyme_Index
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error converting the enzyme number to an enzyme name in #TmpParamFileInfo: ' + Convert(varchar(19), @myError)
        Goto Done
    End

    -----------------------------------------------------------
    -- Display the enzyme name as "none" if the enzyme is 0 or null
    -----------------------------------------------------------
    --
    UPDATE #TmpParamFileInfo
    SET Enzyme = 'none'
    WHERE Len(Isnull(Enzyme, '')) = 0 OR Enzyme = '0'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error finding undefined enzymes in #TmpParamFileInfo: ' + Convert(varchar(19), @myError)
        Goto Done
    End

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[PopulateParamFileInfoTableSequest] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[PopulateParamFileInfoTableSequest] TO [Limited_Table_Write] AS [dbo]
GO
