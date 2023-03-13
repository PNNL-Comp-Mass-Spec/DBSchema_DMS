/****** Object:  StoredProcedure [dbo].[create_signatures_for_job_steps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_signatures_for_job_steps]
/****************************************************
**
**  Desc:   Create signatures for job steps
**
**  Auth:   grk
**          01/30/2009 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/08/2009 mem - Added parameter @debugMode
**          12/21/2009 mem - Added warning message if @debugMode is non-zero and a signature cannot be computed for a step tool
**          03/22/2011 mem - Now using varchar(1024) when extracting the @Value from the XML parameters
**          07/16/2014 mem - Updated capitalization of keywords
**          03/02/2022 mem - Rename parameter @datasetID to @datasetOrDataPackageId
**          04/11/2022 mem - Expand Section and Name to varchar(128)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/09/2023 mem - Use new column names in temporary tables
**          03/13/2023 mem - Fix bug retrieving step tool name from #Job_Steps
**
*****************************************************/
(
    @job int,
    @paramsXML xml,
    @datasetOrDataPackageId int,
    @message varchar(512) output,
    @debugMode tinyint = 0
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Get job parameters into table format
    ---------------------------------------------------
    --
    Declare @Job_Parameters table (
        [Job] int,
        [Step] int,
        [Section] varchar(128),
        [Name] varchar(128),
        [Value] varchar(2000)        -- Warning: if this field is larger than varchar(2000), the creation of @s via string concatenation later in this SP will result in corrupted strings (MEM 01/13/2009)
    )
    --
    INSERT INTO @Job_Parameters
        (Job, Step, [Section], [Name], Value)
    SELECT
        xmlNode.value('@Job', 'varchar(64)') As Job,
        xmlNode.value('@Step_Number', 'varchar(64)') As Step,
        xmlNode.value('@Section', 'varchar(128)') As [Section],
        xmlNode.value('@Name', 'varchar(128)') As [Name],
        xmlNode.value('@Value', 'varchar(2000)') As [Value]         -- If the value is over 2000 characters long, it will be truncated; that's OK
    FROM
        @paramsXML.nodes('//Param') As R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error getting job parameters'
        goto Done
    End

    If @debugMode <> 0
        SELECT '@Job_Parameters' As [Table], *
        FROM @Job_Parameters

    ---------------------------------------------------
    -- Calculate signature and shared resuts folder name
    -- for job steps that have tools that require signature
    ---------------------------------------------------
    --
    Declare @signature int
    Declare @shared int
    Declare @stepTool varchar(64)
    Declare @curStep int
    --
    Declare @prevStep Int = 0
    --
    Declare @continue tinyint = 1
    --
    While @continue = 1
    Begin --<a>

        -- Get next step that requires signature
        --
        Set @curStep = 0
        --
        SELECT TOP 1 @curStep = Step,
                     @stepTool = Tool,
                     @shared = Shared_Result_Version
        FROM #Job_Steps
        WHERE Job = @job AND
              (Shared_Result_Version + Filter_Version) > 0 AND
              Step > @prevStep
        ORDER BY Step


        -- If none found, done, otherwise process
        If @curStep = 0
        Begin
            Set @continue = 0
        End
        Else
        Begin --<b>

            Set @prevStep = @curStep

            ---------------------------------------------------
            -- Get signature for step
            --
            -- Rollup parameter names and values for sections
            -- associated with step's step tool into single string
            --
            -- To allow for more than one instance of a tool in a single script,
            -- look at parameters in sections that either are not locked to any step
            -- (step number is null) or are locked to the current step
            --
            Set @signature = 0

            Declare @s varchar(max) = ''
            --
            SELECT @s = @s + [Name] + '=' + [Value] + ';'
            FROM @Job_Parameters
            WHERE [Section] in (
                SELECT xmlNode.value('@name', 'varchar(128)') SectionName
                FROM   T_Step_Tools CROSS APPLY
                       Parameter_Template.nodes('//section') As R(xmlNode)
                WHERE  [Name] = @stepTool AND
                       ((Step is null) OR (Step = @curStep))
            )
            ORDER BY [Section], [Name]
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @message = 'Error forming global signature string'
                goto Done
            End

            If @myRowCount > 0
            Begin --<c>

                ---------------------------------------------------
                -- Get signature for rolled-up parameter string
                --
                exec @signature = get_signature @s
                --
                If @signature = 0
                Begin
                    Set @message = 'Error calculating signature'
                    goto Done
                End

                If @debugMode <> 0
                    SELECT @signature As Signature, @S As Settings

            End --<c>
            Else
            Begin
                If @debugMode <> 0
                    SELECT 'Warning: Cannot compute signature since could not find a section named "' + @stepTool + '" in column Parameter_Template in table T_Step_Tools' As Message
            End

            ---------------------------------------------------
            -- Calculate shared folder name
            --
            Declare @sharedResultsFolderName varchar(256)
            Set @sharedResultsFolderName = @stepTool + '_' + convert(varchar(12), @shared) + '_' + convert(varchar(12), @signature) + '_' + convert(varchar(12), @datasetOrDataPackageId)

            ---------------------------------------------------
            -- Set signature (and shared results folder name for shared results steps)
            --
            UPDATE #Job_Steps
            SET Signature = @signature,
                Output_Folder_Name = CASE
                                         WHEN @shared > 0 THEN @sharedResultsFolderName
                                         ELSE Output_Folder_Name
                                     END
            WHERE Job = @job AND
                  Step = @curStep

        End --<b>
    End --<a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_signatures_for_job_steps] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_signatures_for_job_steps] TO [Limited_Table_Write] AS [dbo]
GO
