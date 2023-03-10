/****** Object:  StoredProcedure [dbo].[create_steps_for_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_steps_for_job]
/****************************************************
**
**  Desc:
**    Make entries in temporary tables:
**      #Job_Steps
**      #Job_Step_Dependencies
**    for the the given job
**    according to definition of scriptXML
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   08/23/2008 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**          12/05/2008 mem - Changed the formatting of the auto-generated results folder name
**          01/14/2009 mem - Increased maximum Value length in @Job_Parameters to 2000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          01/28/2009 grk - modified for parallelization (http://prismtrac.pnl.gov/trac/ticket/718)
**          01/30/2009 grk - modified output folder name initiation (http://prismtrac.pnl.gov/trac/ticket/719)
**          02/05/2009 grk - modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          05/25/2011 mem - Removed @priority parameter and removed priority column from T_Job_Steps
**          10/17/2011 mem - Added column Memory_Usage_MB
**          04/16/2012 grk - Added error checking for missing step tools
**          09/24/2014 mem - Rename Job in T_Job_Step_Dependencies
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary tables
**
*****************************************************/
(
    @job int,
    @scriptXML xml,
    @resultsFolderName varchar(128),
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- make sure that the tools in the script exist
    ---------------------------------------------------
    --
    DECLARE @missingTools VARCHAR(2048) = ''
    --
    SELECT @missingTools = CASE WHEN @missingTools = '' THEN Tool ELSE @missingTools + ', ' + Tool END
    FROM    ( SELECT    xmlNode.value('@Tool', 'nvarchar(128)') Tool
              FROM      @scriptXML.nodes('//Step') AS R ( xmlNode )
            ) TS
    WHERE   NOT Tool IN ( SELECT [Name] FROM dbo.T_Step_Tools )
    --
    if @missingTools <> ''
    begin
        SET @myError = 51047
        set @message = 'Step tool(s) ' + @missingTools + ' do not exist in tools list'
        goto Done
    end

    ---------------------------------------------------
    -- make set of job steps for job based on scriptXML
    ---------------------------------------------------
    --
    INSERT INTO #Job_Steps (
        Job,
        Step,
        Tool,
        CPU_Load,
        Memory_Usage_MB,
        Shared_Result_Version,
        Filter_Version,
        Dependencies,
        State,
        Output_Folder_Name,
        Special_Instructions
    )
    SELECT
        @job AS Job,
        TS.Step,
        TS.Tool,
        CPU_Load,
        Memory_Usage_MB,
        Shared_Result_Version,
        Filter_Version,
        0 AS Dependencies,
        1 AS State,
        @resultsFolderName,
        Special_Instructions
    FROM
        (
            SELECT
                xmlNode.value('@Number', 'nvarchar(128)') Step,
                xmlNode.value('@Tool', 'nvarchar(128)') Tool,
                xmlNode.value('@Special', 'nvarchar(128)') Special_Instructions
            FROM
                @scriptXML.nodes('//Step') AS R(xmlNode)
        ) TS INNER JOIN
        T_Step_Tools ON TS.Tool = T_Step_Tools.Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error copying job steps from script'
        goto Done
    end

    ---------------------------------------------------
    -- make set of step dependencies based on scriptXML
    ---------------------------------------------------
    --
    INSERT INTO #Job_Step_Dependencies
    (
        Step,
        Target_Step,
        Condition_Test,
        Test_Value,
        Enable_Only,
        Job
    )
    SELECT
        xmlNode.value('../@Number', 'nvarchar(24)') Step,
        xmlNode.value('@Step_Number', 'nvarchar(24)') Target_Step,
        xmlNode.value('@Test', 'nvarchar(128)') Condition_Test,
        xmlNode.value('@Value', 'nvarchar(256)') Test_Value,
        isnull(xmlNode.value('@Enable_Only', 'nvarchar(24)'), 0) Enable_Only,
        @job AS Job
    FROM
        @scriptXML.nodes('//Depends_On') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error copying job step dependencies from script'
        goto Done
    end

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_steps_for_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_steps_for_job] TO [Limited_Table_Write] AS [dbo]
GO
