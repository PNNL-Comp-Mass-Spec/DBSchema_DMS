/****** Object:  StoredProcedure [dbo].[add_update_tmp_param_tab_entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_tmp_param_tab_entry]
/****************************************************
**
**  Desc:   Adds or updates an entry in temp table #T_Tmp_ParamTab
**          This procedure is typically called by get_job_param_table
**
**          The calling procedure must create table #T_Tmp_ParamTab
**
**              CREATE TABLE #T_Tmp_ParamTab
**              (
**                  [Step_Number] Varchar(24),
**                  [Section] Varchar(128),
**                  [Name] Varchar(128),
**                  [Value] Varchar(2000)
**              )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   04/20/2011 mem - Initial Version
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @section varchar(128),      -- Example: JobParameters
    @paramName varchar(128),    -- Example: AMTDBServer
    @paramValue varchar(2000)   -- Example: Elmer
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ---------------------------------------------------
    -- Use a Merge statement to add or update the value
    ---------------------------------------------------
    --
    MERGE #T_Tmp_ParamTab AS target
    USING
        (SELECT Null AS Step_Number,
                @Section AS Section,
                @ParamName AS Name,
                @ParamValue AS Value
        ) AS Source ( Step_Number, Section, Name, Value)
    ON (target.Section = source.Section AND
        target.Name = source.Name)
    WHEN Matched AND ( target.value <> source.value )
        THEN UPDATE
            Set Value = source.Value
    WHEN Not Matched THEN
        INSERT (Step_Number, Section, Name, Value)
        VALUES (source.Step_Number, source.Section, source.Name, source.Value);


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_tmp_param_tab_entry] TO [DDL_Viewer] AS [dbo]
GO
