/****** Object:  StoredProcedure [dbo].[check_add_special_processing_param] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[check_add_special_processing_param]
/****************************************************
**
**  Desc:   Looks for a tagged entry in the Special_Processing parameter of #T_Tmp_ParamTab
**          If found, then adds it as a normal parameter in the JobParameters section
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
**  Auth:   mem
**  Date:   04/20/2011 mem - Initial version
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @tagName varchar(64)
)
AS
    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @TagNameWithColon varchar(65)
    declare @TagValue varchar(256)

    IF EXISTS (SELECT * FROM #T_Tmp_ParamTab WHERE [Name] = 'Special_Processing' AND IsNull([Value], '') <> '')
    Begin

        set @TagNameWithColon = @TagName + ':'
        set @TagValue = ''

        SELECT @TagValue = dbo.extract_tagged_name(@TagNameWithColon, Value)
        FROM #T_Tmp_ParamTab
        WHERE [Name] = 'Special_Processing'

        If @TagValue <> ''
            exec add_update_tmp_param_tab_entry 'JobParameters', @TagName, @TagValue

    End

    RETURN

GO
GRANT VIEW DEFINITION ON [dbo].[check_add_special_processing_param] TO [DDL_Viewer] AS [dbo]
GO
