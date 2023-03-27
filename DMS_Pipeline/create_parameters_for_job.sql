/****** Object:  StoredProcedure [dbo].[create_parameters_for_job] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[create_parameters_for_job]
/****************************************************
**
**  Desc:
**      Get parameters for given job as XML, populating output parameter @paramsXML
**
**      In addition, make entries in temporary table #Job_Parameters (created by the calling procedure)
**
**      CREATE TABLE #Job_Parameters (
**          [Job] int NOT NULL,
**          [Parameters] xml NULL
**      )
**
**  Note:   The job parameters come from the DMS5 database (via get_job_param_table),
**          and not from the T_Job_Parameters table local to this DB
**
**  Auth:   grk
**          01/31/2009 grk - Initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**          02/08/2009 mem - Added parameter @debugMode
**          06/01/2009 mem - Switched from S_get_job_param_table (which pointed to a stored procedure in DMS5)
**                           to get_job_param_table, which is local to this database (Ticket #738, http://prismtrac.pnl.gov/trac/ticket/738)
**          01/05/2010 mem - Added parameter @settingsFileOverride
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/26/2023 mem - Update logic to handle data package based jobs (which should have dataset name 'Aggregation')
**
*****************************************************/
(
    @job int,
    @paramsXML xml output,
    @message varchar(512) output,
    @settingsFileOverride varchar(256) = '',    -- When defined, then will use this settings file name instead of the one obtained with V_DMS_PipelineJobParameters (in get_job_param_table)
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0

    Declare @dataPackageID Int = 0
    
    Declare @continue tinyint
    Declare @entryID int

    Declare @section varchar(64)
    Declare @name varchar(128)
    Declare @value varchar(2000)

    set @message = ''

    ---------------------------------------------------
    -- Get job parameters from main database
    -- Procedure get_job_param_table uses view V_DMS_PipelineJobParameters, which references V_Get_Pipeline_Job_Parameters in DMS5
    ---------------------------------------------------
    --
    Declare @Job_Parameters table (
        [Job] int,
        [Step_Number] int,          -- This will be null for every row since get_job_param_table does not consider job step
        [Section] varchar(64),
        [Name] varchar(128),
        [Value] varchar(2000)       -- Warning: if this field is larger than varchar(2000), the creation of @s via string concatenation later in this SP will result in corrupted strings (MEM 01/13/2009)
    )
    --
    INSERT INTO @Job_Parameters
        (Job, Step_Number, [Section], [Name], Value)
    execute get_job_param_table @job, @settingsFileOverride, @debugMode = @debugMode
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    begin
        set @message = 'Error getting job parameters'
        goto Done
    end

    If @debugMode <> 0
    Begin
        SELECT '@Job_Parameters' AS [Table], * 
        FROM @Job_Parameters
    End

    -- Check whether this job is a data package based job
    SELECT @dataPackageID = DataPkgID
    FROM T_Jobs
    WHERE Job = @job
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0 And @dataPackageID > 0 And Exists (SELECT * FROM T_Job_Parameters Where Job = @job)
    Begin
        ---------------------------------------------------
        -- This is a data package based job with existing parameters
        -- Selectively update the existing job parameters using the parameters in @Job_Parameters
        ---------------------------------------------------

        Declare @Job_Parameters_Merged table (
            [Job] int,
            [Step_Number] int,          -- This will be null for every row since get_job_param_table does not consider job step
            [Section] varchar(64),
            [Name] varchar(128),
            [Value] varchar(2000)
        )

        -- Populate @Job_Parameters_Merged with the existing job parameters

        INSERT INTO @Job_Parameters_Merged (Job, Step_Number, Section, Name, Value)
        SELECT @job,
               Null,
               [Section],
               [Name],
               [Value]
        FROM ( SELECT xmlNode.value('@Section', 'varchar(128)')  AS [Section],
                      xmlNode.value('@Name',    'varchar(128)')  AS [Name],
                      xmlNode.value('@Value',   'varchar(4000)') AS [Value]
               FROM T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
               WHERE T_Job_Parameters.Job = @job
             ) LookupQ

        -- Update @Job_Parameters_Merged using selected rows in @Job_Parameters
        -- Only update settings that come from T_Analysis_Job

        DECLARE @Job_Parameters_To_Update table (
            [Entry_ID] int identity(1,1),
            [Section] varchar(64),
            [Name] varchar(128)
        )

        INSERT INTO @Job_Parameters_To_Update ([Section], [Name])
        VALUES ('JobParameters', 'DatasetID'),
               ('JobParameters', 'SettingsFileName'),
               ('PeptideSearch', 'LegacyFastaFileName'),
               ('PeptideSearch', 'OrganismName'),
               ('PeptideSearch', 'ParamFileName'),
               ('PeptideSearch', 'ParamFileStoragePath'),
               ('PeptideSearch', 'ProteinCollectionList'),
               ('PeptideSearch', 'ProteinOptions')

        Set @continue = 1
        Set @entryID = 0

        While @continue > 0
        Begin
            SELECT TOP 1
                   @entryID = Entry_ID,
                   @section = Section,
                   @name = Name
            FROM @Job_Parameters_To_Update
            WHERE Entry_ID > @entryID
            ORDER BY Entry_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin            
                SELECT @value = Value 
                FROM @Job_Parameters 
                WHERE Section = @section AND Name = @name

                If @@rowcount > 0
                Begin
                    If Exists (Select * From @Job_Parameters_Merged WHERE Section = @section AND Name = @name)
                    Begin
                        UPDATE @Job_Parameters_Merged
                        set VALUE = @value
                        WHERE Section = @section AND Name = @name
                    End
                    Else
                    Begin
                        INSERT INTO @Job_Parameters_Merged (Job, Section, Name, Value)
                        VALUES (@job, @section, @name,  @value);
                    End
                End
            End
        End -- </while loop>

        INSERT INTO #Job_Parameters (Job, Parameters)
        SELECT @job,
               ( SELECT [Step_Number],
                        [Section],
                        [Name],
                        [Value]
                 FROM @Job_Parameters_Merged Param
                 FOR XML AUTO )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End
    Else
    Begin
        ---------------------------------------------------
        -- Convert job parameters to XML
        ---------------------------------------------------
        --
        INSERT INTO #Job_Parameters (Job, Parameters)
        SELECT @job,
               ( SELECT [Step_Number],
                        [Section],
                        [Name],
                        [Value]
                 FROM @Job_Parameters Param
                 FOR XML AUTO )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        begin
            set @message = 'Error converting parameters into XML and storing in #Job_Parameters'
            goto Done
        end
    End

    ---------------------------------------------------
    -- Store the job parameters in @paramsXML
    ---------------------------------------------------
    --
    SELECT @paramsXML = Parameters
    FROM #Job_Parameters
    WHERE Job = @job

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[create_parameters_for_job] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[create_parameters_for_job] TO [Limited_Table_Write] AS [dbo]
GO
