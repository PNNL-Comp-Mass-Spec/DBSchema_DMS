/****** Object:  StoredProcedure [dbo].[CreateSignaturesForJobSteps] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.CreateSignaturesForJobSteps
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
**    
*****************************************************/
(
    @job int,
    @pXML xml,
    @datasetID int,
    @message varchar(512) output,
    @DebugMode tinyint = 0
)
As
    Set nocount on

    Declare @myError int
    Set @myError = 0

    Declare @myRowCount int
    Set @myRowCount = 0

    Set @message = ''

    ---------------------------------------------------
    -- get job parameters into table format
    ---------------------------------------------------
    --
    Declare @Job_Parameters table (
        [Job] int,
        [Step_Number] int,
        [Section] varchar(64),
        [Name] varchar(128),
        [Value] varchar(1024)        -- Warning: if this field is larger than varchar(2000) then the creation of @s via string concatenation later in this SP will result in corrupted strings (MEM 01/13/2009)
    )
    --
    INSERT INTO @Job_Parameters
        (Job, Step_Number, [Section], [Name], Value)
    SELECT 
        xmlNode.value('@Job', 'varchar(64)') As Job,
        xmlNode.value('@Step_Number', 'varchar(64)') As Step_Number,
        xmlNode.value('@Section', 'varchar(64)') As [Section],
        xmlNode.value('@Name', 'varchar(64)') As [Name],
        xmlNode.value('@Value', 'varchar(1024)') As [Value]
    FROM
        @pXML.nodes('//Param') As R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error getting job parameters'
        goto Done
    End

    If @DebugMode <> 0
        SELECT '@Job_Parameters' As [Table], *
        FROM @Job_Parameters

    ---------------------------------------------------
    -- calculate signature and shared resuts folder name
    -- for job steps that have tools that require signature
    ---------------------------------------------------
    --
    Declare @signature int
    Declare @Shared int
    Declare @stepTool varchar(64)
    Declare @curStep int
    --
    Declare @prevStep int
    Set @prevStep = 0
    --
    Declare @done tinyint
    Set @done = 0
    --
    While @done = 0
    Begin --<a>
        -- get next step that requires signature
        --
        Set @curStep = 0
        --
        SELECT TOP 1 @curStep = Step_Number,
                     @stepTool = Step_Tool,
                     @Shared = Shared_Result_Version
        FROM #Job_Steps
        WHERE Job = @job AND
              (Shared_Result_Version + Filter_Version) > 0 AND
              Step_Number > @prevStep
        ORDER BY Step_Number


        -- If none found, done, otherwise process
        If @curStep = 0
            Set @done = 1
        Else
        Begin --<b>
            Set @prevStep = @curStep
            ---------------------------------------------------
            -- get signature for step
            -- rollup parameter names and values for sections
            -- associated with step's step tool into single string
            --
            -- to allow for more than one instance of a tool
            -- in a single script, look at parameters in sections
            -- that either are not locked to any step
            -- (step number is null) or are locked to the current step
            --
            Set @signature = 0
            --
            Declare @s varchar(max)
            Set @s = ''
            --
            SELECT @s = @s + [Name] + '=' + [Value] + ';'
            FROM @Job_Parameters
            WHERE [Section] in (
                SELECT xmlNode.value('@name', 'varchar(128)') SectionName
                FROM   T_Step_Tools CROSS APPLY
                       Parameter_Template.nodes('//section') As R(xmlNode)
                WHERE  [Name] = @stepTool AND
                       ((Step_Number is null) OR (Step_Number = @curStep))
            )
            ORDER BY [Section], [Name]
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error forming global signature string'
                goto Done
            End

            If @myRowCount > 0
            Begin --<c>
                ---------------------------------------------------
                -- get signature for rolled-up parameter string
                --
                exec @signature = GetSignature @s
                --
                If @signature = 0
                Begin
                    Set @message = 'Error calculating signature'
                    goto Done
                End

                If @DebugMode <> 0
                    SELECT @signature As Signature, @S As Settings

            End --<c>
            Else
            Begin
                If @DebugMode <> 0
                    SELECT 'Warning: Cannot compute signature since could not find a section named "' + @stepTool + '" in column Parameter_Template in table T_Step_Tools' As Message
            End

            ---------------------------------------------------
            -- calculate shared folder name
            --
            Declare @SharedResultsFolderName varchar(256)
            Set @SharedResultsFolderName = @stepTool + '_' + convert(varchar(12), @Shared) + '_' + convert(varchar(12), @Signature) + '_' + convert(varchar(12), @DatasetID)

            ---------------------------------------------------
            -- Set signature (and shared results folder name for shared results steps)
            --
            UPDATE #Job_Steps
            SET Signature = @signature,
                Output_Folder_Name = CASE
                                         WHEN @Shared > 0 THEN @SharedResultsFolderName
                                         ELSE Output_Folder_Name
                                     END
            WHERE Job = @job AND
                  Step_Number = @curStep


        End --<b>
    End --<a>

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CreateSignaturesForJobSteps] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateSignaturesForJobSteps] TO [Limited_Table_Write] AS [dbo]
GO
