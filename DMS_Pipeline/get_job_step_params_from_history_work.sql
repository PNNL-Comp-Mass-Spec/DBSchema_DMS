/****** Object:  StoredProcedure [dbo].[get_job_step_params_from_history_work] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_job_step_params_from_history_work]
/****************************************************
**
**  Desc:
**      Populates temporary table #Tmp_JobParamsTable with the parameters for the given job and step
**      Note: Data comes from table T_Job_Parameters_History in the DMS_Pipeline DB, not from DMS5
**
**      The calling procedure must create temporary table #Tmp_JobParamsTable
**
**      Create Table #Tmp_JobParamsTable (
**          [Section] Varchar(128),
**          [Name] Varchar(128),
**          [Value] Varchar(max)
**      )
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/31/2013 mem - Ported from get_job_step_params_work
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/20/2016 mem - Update procedure name shown when using @DebugMode
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          04/11/2022 mem - Use varchar(4000) when extracting values from the XML
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobNumber int,
    @stepNumber int,
    @message varchar(512) = '' output,
    @debugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @stepTool varchar(64) = ''
    Declare @inputFolderName varchar(128) = ''
    Declare @outputFolderName varchar(128) = ''
    Declare @DataPackageID int = 0

    set @myRowCount = 0

    -- Clear the outputs
    set @message = ''
    set @DebugMode = IsNull(@DebugMode, 0)

    If @DebugMode <> 0
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_from_history_work: Get basic job step parameters'

    ---------------------------------------------------
    -- Get basic job step parameters
    ---------------------------------------------------
    --
    SELECT
        @stepTool = Step_Tool,
        @inputFolderName = Input_Folder_Name,
        @outputFolderName = Output_Folder_Name
    FROM  T_Job_Steps_History
    WHERE
        Job = @jobNumber AND
        Step_Number = @stepNumber AND
        Most_Recent_Entry = 1
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting basic job step parameters'
        goto Done
    end
    --
    if @myRowCount = 0
    begin
        set @myError = 42
        set @message = 'Could not find basic job step parameters'
        goto Done
    end

    If @DebugMode > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_from_history_work: Get shared results folder name list'

    ---------------------------------------------------
    -- Lookup data package ID in T_Jobs
    ---------------------------------------------------
    --
    SELECT @DataPackageID = DataPkgID
    FROM T_Jobs_History
    WHERE Job = @jobNumber AND
        Most_Recent_Entry = 1

    Set @DataPackageID = IsNull(@DataPackageID, 0)

    ---------------------------------------------------
    -- Get shared results folder name list
    -- Be sure to sort by increasing step number so that the newest shared result folder is last
    ---------------------------------------------------
    declare @sharedFolderList varchar(1024)
    set @sharedFolderList = Null
    --
    SELECT @sharedFolderList = COALESCE(@sharedFolderList + ', ',
                                        ISNULL(@sharedFolderList, '')) +
                               Output_Folder_Name
    FROM T_Job_Steps_History
    WHERE (Job = @jobNumber) AND
          (Shared_Result_Version > 0) AND
          (State IN (3, 5)) AND
          Most_Recent_Entry = 1
    ORDER BY Step_Number
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting shared folder name list'
        goto Done
    end

    If @DebugMode > 1
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_from_history_work: Get job step parameters'

    ---------------------------------------------------
    -- get input and output folder names for individual steps
    -- (used by aggregation jobs created in broker)
    ---------------------------------------------------

    DECLARE @stepOutputFolderName VARCHAR(128) = ''
    DECLARE @stepInputFolderName VARCHAR(128) = ''

    SELECT  @stepOutputFolderName = 'Step_' + CONVERT(VARCHAR(6), TJS.Step_Number)
            + '_' + TST.Tag
    FROM    T_Job_Steps_History TJS
            INNER JOIN T_Step_Tools TST ON TJS.Step_Tool = TST.Name
    WHERE   TJS.Job = @jobNumber AND
            TJS.Step_Number = @stepNumber AND
            TJS.Most_Recent_Entry = 1


    SELECT  @stepInputFolderName = 'Step_'
            + CONVERT(VARCHAR(6), TJS.Step_Number) + '_NotDefined'
    FROM  T_Job_Steps_History AS TJS
            INNER JOIN T_Step_Tools AS TST ON TJS.Step_Tool = TST.Name
    WHERE   ( TJS.Job = @jobNumber ) AND
            ( TJS.Step_Number = @stepNumber ) AND
            TJS.Most_Recent_Entry = 1

    ---------------------------------------------------
    -- Get job step parameters
    ---------------------------------------------------
    --
    declare @stepParmSectionName varchar(32)
    set @stepParmSectionName = 'StepParameters'
    --
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Job', @jobNumber)
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Step', @stepNumber)
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepTool', @stepTool)
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'InputFolderName', @inputFolderName)
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'OutputFolderName', @outputFolderName)
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'SharedResultsFolders', @sharedFolderList)

    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepOutputFolderName', @stepOutputFolderName)
    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepInputFolderName', @stepInputFolderName)


    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], Value) VALUES ('JobParameters', 'DataPackageID', @DataPackageID)


    If @DebugMode <> 0
        Print Convert(varchar(32), GetDate(), 21) + ', ' + 'get_job_step_params_from_history_work: Get job parameters using cross apply'

    ---------------------------------------------------
    -- Get job parameters
    -- Exclude DataPackageID since we obtained that from T_Jobs
    ---------------------------------------------------
    --
    -- To allow for more than one instance of a tool in a single script,
    --  look at parameters in sections that either are not locked to any step (step number is null)
    --  or are locked to the current step
    --
    -- Prior to June 2012, step locking would use notation like this:
    --  <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="2" />
    --
    -- We now use notatio like this:
    --  <Param Section="2_Ape" Name="ApeMTSDatabase" Value="MT_R_norvegicus_P748" Step="Yes (2)" />
    --
    -- Thus, the following uses a series of REPLACE commands to remove text from the Step attribute,
    --  replacing the following three strings with ""
    --   "Yes ("
    --   "No ("
    --   ")"

    INSERT INTO #Tmp_JobParamsTable ([Section], [Name], [Value])
    SELECT Section, Name, [Value]
    FROM ( SELECT Section,
                  Name,
                  [Value],
                  IsNull(Try_Parse(Step as int), 0) AS StepNumber
           FROM ( SELECT xmlNode.value('@Section', 'varchar(128)') AS Section,
                         xmlNode.value('@Name', 'varchar(128)') AS Name,
                         xmlNode.value('@Value', 'varchar(4000)') AS [Value],
                         REPLACE(REPLACE(REPLACE( IsNull(xmlNode.value('@Step', 'varchar(128)'), '') , 'Yes (', ''), 'No (', ''), ')', '') AS Step
                  FROM T_Job_Parameters_History cross apply Parameters.nodes('//Param') AS R(xmlNode)
                  WHERE T_Job_Parameters_History.Job = @jobNumber AND
                        T_Job_Parameters_History.Most_Recent_Entry = 1
                ) LookupQ
         ) ConvertQ
    WHERE Name <> 'DataPackageID' AND
          (StepNumber = 0 OR
           StepNumber = @stepNumber)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting job parameters'
        goto Done
    end

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_step_params_from_history_work] TO [DDL_Viewer] AS [dbo]
GO
