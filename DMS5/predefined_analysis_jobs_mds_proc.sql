/****** Object:  StoredProcedure [dbo].[predefined_analysis_jobs_mds_proc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[predefined_analysis_jobs_mds_proc]
/****************************************************
**
**  Desc:
**      Evaluate predefined analysis rules for given list of datasets
**      Return a table of the jobs that would be created
**
**      Used by web page https://dms2.pnl.gov/predefined_analysis_preview_mds/param
**
**  Auth:   grk
**  Date:   06/23/2005
**          03/28/2006 grk - added protein collection fields
**          04/04/2006 grk - increased sized of param file name
**          03/16/2007 mem - Replaced processor name with associated processor group (Ticket #388)
**          04/11/2008 mem - Now passing @RaiseErrorMessages to evaluate_predefined_analysis_rules
**          07/22/2008 grk - Changed protein collection column names for final list report output
**          02/09/2011 mem - Now passing @ExcludeDatasetsNotReleased and @CreateJobsForUnreviewedDatasets to evaluate_predefined_analysis_rules
**          02/16/2011 mem - Added support for Propagation Mode (aka Export Mode)
**          02/20/2012 mem - Now using a temporary table to track the dataset names in @datasetList
**          02/22/2012 mem - Switched to using a table-variable for dataset names (instead of a physical temporary table)
**          05/03/2012 mem - Added support for the Special Processing field
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list
**          06/30/2022 mem - Rename parameter file column
**          11/09/2022 mem - Rename stored procedure from evaluate_predefined_analysis_rulesMDS to predefined_analysis_jobs_mds_proc
**          01/26/2023 mem - Add predefine_id to the output table, remove Processor_Group, and change names to lowercase
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetList varchar(3500),
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @DatasetName varchar(128)
    Declare @result int

    Set @datasetList = IsNull(@datasetList, '')
    set @message = ''

    ---------------------------------------------------
    -- Temporary job holding table to receive created jobs
    -- This table is populated in evaluate_predefined_analysis_rules
    ---------------------------------------------------

    CREATE TABLE #JX (
        predefine_id int,
        dataset varchar(128),
        priority varchar(8),
        analysisToolName varchar(64),
        paramFileName varchar(255),
        settingsFileName varchar(128),
        organismDBName varchar(128),
        organismName varchar(128),
        proteinCollectionList varchar(512),
        proteinOptionsList varchar(256),
        ownerUsername varchar(128),
        comment varchar(128),
        associatedProcessorGroup varchar(64),
        numJobs int,
        propagationMode tinyint,
        specialProcessing varchar(512),
        ID int IDENTITY (1, 1) NOT NULL
    )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Could not create temporary table'
        RAISERROR (@message, 10, 1)
        return @myError
    end

    ---------------------------------------------------
    -- Process list into datasets
    -- and make job for each one
    ---------------------------------------------------

    Declare @tblDatasetsToProcess Table
    (
        EntryID int identity(1,1),
        Dataset varchar(256)
    )

    INSERT INTO @tblDatasetsToProcess (Dataset)
    SELECT Value
    FROM dbo.parse_delimited_list(@datasetList, ',', 'evaluate_predefined_analysis_rulesMDS')
    WHERE Len(Value) > 0
    ORDER BY Value

    ---------------------------------------------------
    -- Process list into datasets and get set of generated jobs
    -- for each one into job holding table
    ---------------------------------------------------
    --
    Declare @done int = 0
    Declare @count int = 0
    Declare @EntryID int = 0

    while @done = 0 and @myError = 0
    begin

        SELECT TOP 1 @EntryID = EntryID,
                     @DatasetName = Dataset
        FROM @tblDatasetsToProcess
        WHERE EntryID > @EntryID
        ORDER BY EntryID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        If @myRowCount = 0
            Set @Done = 1
        Else
        Begin
            ---------------------------------------------------
            -- Add jobs created for the dataset to the
            -- job holding table (#JX)
            ---------------------------------------------------
            set @message = ''
            exec @result = evaluate_predefined_analysis_rules
                                    @DatasetName,
                                    'Export Jobs',
                                    @message output,
                                    @RaiseErrorMessages=0,
                                    @ExcludeDatasetsNotReleased=0,
                                    @CreateJobsForUnreviewedDatasets=1

            set @count = @count + 1

        End
    end

    ---------------------------------------------------
    -- Dump contents of job holding table
    ---------------------------------------------------

    SELECT
        id,
        'Entry' AS job,
        predefine_id,
        dataset AS dataset,
        numJobs AS jobs,
        analysistoolname AS tool,
        priority AS pri,
        comment AS comment,
        paramFileName AS param_file,
        settingsFileName AS settings_file,
        organismName AS organism,
        proteinCollectionList AS protein_collections,
        proteinOptionsList AS protein_options,
        organismDBName AS organism_db_name,
        specialProcessing AS special_processing,
        ownerUsername AS owner,
        CASE propagationMode WHEN 0 THEN 'Export' ELSE 'No Export' END AS export_mode
    FROM #JX

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[predefined_analysis_jobs_mds_proc] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[predefined_analysis_jobs_mds_proc] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[predefined_analysis_jobs_mds_proc] TO [Limited_Table_Write] AS [dbo]
GO
