/****** Object:  StoredProcedure [dbo].[get_param_file_crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_param_file_crosstab]
/****************************************************
**
**  Desc:
**      Returns a crosstab table displaying modification details
**      for the parameter file(s) for the given analysis tool
**
**      Used by web page https://dms2.pnl.gov/get_paramfile_crosstab/param
**
**  Return values: 0: success, otherwise, error code
**
**  Date:   12/05/2006 mem - Initial version (Ticket #337)
**          12/11/2006 mem - Renamed from GetSequestParamFileCrosstab to get_param_file_crosstab (Ticket #342)
**                         - Added parameters @parameterFileTypeName and @showValidOnly
**                         - Updated to call populate_param_file_info_table_sequest and populate_param_file_mod_info_table
**          04/07/2008 mem - Added parameters @previewSql, @massModFilterTextColumn, and @massModFilterText
**          05/19/2009 mem - Now returning column Job_Usage_Count
**          02/12/2010 mem - Expanded @parameterFileFilter to varchar(255)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/14/2023 mem - Rename argument @parameterFileTypeName to @analysisToolName and rearrange procedure arguments
**
*****************************************************/
(
    @analysisToolName varchar(64) = 'MSGFPlus_MzML',    -- Analysis tool name
    @parameterFileFilter varchar(255) = '',             -- Optional parameter file name filter
    @showValidOnly tinyint = 0,                         -- Set to 1 to only show "Valid" parameter files
    @showModSymbol tinyint = 0,                         -- Set to 1 to display the modification symbol
    @showModName tinyint = 1,                           -- Set to 1 to display the modification name
    @showModMass tinyint = 1,                           -- Set to 1 to display the modification mass
    @useModMassAlternativeName tinyint = 1,
    @massModFilterTextColumn varchar(64) = '',          -- If text is defined here, then the @massModFilterText filter is only applied to column(s) whose name matches this
    @massModFilterText varchar(64) = '',                -- If text is defined here, then results are filtered to only show rows that contain this text in one of the mass mod columns
    @previewSql tinyint = 0,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @paramFileInfoColumnList varchar(512) = ''

    Declare @s varchar(max) = ''
    Declare @massModFilterSql varchar(4000) = ''

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @analysisToolName          = IsNull(@analysisToolName, 'MSGFPlus_MzML')
    Set @parameterFileFilter       = IsNull(@parameterFileFilter, '')
    Set @showValidOnly             = IsNull(@showValidOnly, 0)
    Set @showModSymbol             = IsNull(@showModSymbol, 0)
    Set @showModName               = IsNull(@showModName, 1)
    Set @showModMass               = IsNull(@showModMass, 1)
    Set @useModMassAlternativeName = IsNull(@useModMassAlternativeName, 1)
    Set @massModFilterTextColumn   = IsNull(@massModFilterTextColumn, '')
    Set @massModFilterText         = IsNull(@massModFilterText, '')
    Set @previewSql                = IsNull(@previewSql, 0)
    Set @message = ''

    -- Make sure @analysisToolName corresponds to an analysis tool with entries in T_Param_File_Mass_Mods

    If Not Exists (
        SELECT PFMM.Mod_Entry_ID
        FROM T_Param_File_Mass_Mods PFMM
             INNER JOIN T_Param_Files PF
               ON PFMM.param_file_id = PF.param_file_id
             INNER JOIN T_Analysis_Tool AnTool
               ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType
        WHERE AnTool.AJT_toolName = @analysisToolName
    )
    Begin
        Set @message = 'Unknown analysis tool: ' + @analysisToolName + ' (rows not found in T_Param_File_Mass_Mods); should be MSGFPlus_MzML, MaxQuant, DiaNN, XTandem, etc.'
        Set @myError = 50000
        Goto Done
    End

    If Len(@parameterFileFilter) > 0
    Begin
        If CharIndex('%', @parameterFileFilter) = 0
        Begin
            Set @parameterFileFilter = '%' + @parameterFileFilter + '%'
        End
    End
    Else
    Begin
        Set @parameterFileFilter = '%'
    End

    -- Assure that one of the following is non-zero
    If @showModSymbol = 0 AND @showModName = 0 AND @showModMass = 0
        Set @showModName = 1


    -----------------------------------------------------------
    -- Create some temporary tables
    -----------------------------------------------------------

    CREATE TABLE #TmpParamFileInfo (
        Param_File_ID Int NOT NULL,
        Date_Created datetime NULL,
        Date_Modified datetime NULL,
        Job_Usage_Count int NULL
    )
    CREATE UNIQUE CLUSTERED INDEX #IX_TempTable_ParamFileInfo_Param_File_ID ON #TmpParamFileInfo(Param_File_ID)

    CREATE TABLE #TmpParamFileModResults (
        Param_File_ID int
    )
    CREATE UNIQUE INDEX #IX_TempTable_TmpParamFileModResults_Param_File_ID ON #TmpParamFileModResults(Param_File_ID)

    -----------------------------------------------------------
    -- Populate a temporary table with the parameter files
    -- that correspond to tool @analysisToolName and
    -- match @parameterFileFilter (which will be '%' if it was '')
    -----------------------------------------------------------

    INSERT INTO #TmpParamFileInfo (Param_File_ID, Date_Created, Date_Modified, Job_Usage_Count)


    SELECT PF.Param_File_ID, PF.Date_Created, PF.Date_Modified, PF.Job_Usage_Count
    FROM T_Param_Files PF
         INNER JOIN T_Analysis_Tool AnTool
           ON PF.Param_File_Type_ID = AnTool.AJT_paramFileType
    WHERE AnTool.AJT_toolName = @analysisToolName AND
          (PF.Valid = 1 OR @showValidOnly = 0) AND
          PF.Param_File_Name LIKE @parameterFileFilter
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error finding matching parameter files: ' + Convert(varchar(19), @myError)
        goto done
    End

    -----------------------------------------------------------
    -- Possibly append some additional columns to #TmpParamFileInfo,
    --  to be included at the beginning of the crosstab report
    -----------------------------------------------------------

    If @analysisToolName = 'Sequest'
    Begin
        Exec @myError = populate_param_file_info_table_sequest
                                @paramFileInfoColumnList = @paramFileInfoColumnList output,
                                @message = @message output
        If @myError <> 0
            Goto Done
    End

    -----------------------------------------------------------
    -- Populate #TmpParamFileModResults
    -----------------------------------------------------------

    Exec @myError = populate_param_file_mod_info_table
                        @showModSymbol, @showModName, @showModMass,
                        @useModMassAlternativeName,
                        @massModFilterTextColumn,
                        @massModFilterText,
                        @massModFilterSql = @massModFilterSql output,
                        @message = @message output,
                        @previewSql = @previewSql
    If @myError <> 0
        Goto Done

    -----------------------------------------------------------
    -- Return the results
    -----------------------------------------------------------
    Set @s = ''
    Set @s = @s + ' SELECT PF.Param_File_Name, PF.Param_File_Description, PF.Job_Usage_Count, '

    If Len(IsNull(@paramFileInfoColumnList, '')) > 0
        Set @s = @s +      @paramFileInfoColumnList + ', '

    Set @s = @s +        ' PFMR.*,'
    Set @s = @s +        ' PF.Date_Created, PF.Date_Modified, PF.Valid'
    Set @s = @s + ' FROM #TmpParamFileInfo PFI INNER JOIN'
    Set @s = @s +    ' T_Param_Files PF ON PFI.Param_File_ID = PF.Param_File_ID LEFT OUTER JOIN'
    Set @s = @s +    ' #TmpParamFileModResults PFMR ON PFI.Param_File_ID = PFMR.Param_File_ID'

    If Len(@massModFilterSql) > 0
        Set @s = @s + ' WHERE ' + @massModFilterSql

    Set @s = @s + ' ORDER BY PF.Param_File_Name'

    If @previewSql <> 0
        Print @s
    Else
        Exec (@s)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        set @message = 'Error returning the results: ' + Convert(varchar(19), @myError)
        goto done
    End

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_param_file_crosstab] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_param_file_crosstab] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_param_file_crosstab] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_param_file_crosstab] TO [Limited_Table_Write] AS [dbo]
GO
