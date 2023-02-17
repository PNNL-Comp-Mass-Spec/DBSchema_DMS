/****** Object:  StoredProcedure [dbo].[GetJobStepParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetJobStepParams]
/****************************************************
**
**  Desc:   Populate a temporary table with job step parameters for given job step
**          Data comes from tables T_Jobs, T_Job_Steps, and T_Job_Parameters in the DMS_Capture DB, not from DMS5
**
**  The calling procedure must create this temporary table:
**
**      CREATE TABLE #ParamTab (
**            [Section] Varchar(128),
**            [Name] Varchar(128),
**            [Value] Varchar(max)
**        )
**
**    Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   09/08/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**          08/30/2013 mem - Added MyEMSL_Status_URI
**          01/04/2016 mem - Added EUS_InstrumentID, EUS_ProposalID, and EUS_UploaderID
**          06/15/2017 mem - Only append /xml to the MyEMSL status URI if it contains /status/
**          06/12/2018 mem - Now calling GetMetadataForDataset
**          05/17/2019 mem - Switch from folder to directory
**
*****************************************************/
(
    @jobNumber int,
    @stepNumber int,
    @message varchar(512) output,
    @DebugMode tinyint = 0
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    --
    Declare @stepTool varchar(64)
    Declare @inputDirectoryName varchar(128)
    Declare @outputDirectoryName varchar(128)
    Declare @resultsDirectoryName varchar(128)
    Declare @MyEMSLStatusURI varchar(128)

    Declare @EUSInstrumentID int
    Declare @EUSProposalID varchar(10)
    Declare @EUSUploaderID int

    set @stepTool = ''
    set @inputDirectoryName = ''
    set @outputDirectoryName = ''
    set @resultsDirectoryName = ''
    set @MyEMSLStatusURI = ''

    set @EUSInstrumentID = 0
    set @EUSProposalID = ''
    set @EUSUploaderID = 0

    set @message = ''

    ---------------------------------------------------
    -- Get basic job step parameters
    ---------------------------------------------------
    --
    SELECT @stepTool = Step_Tool,
           @inputDirectoryName = Input_Folder_Name,
           @outputDirectoryName = Output_Folder_Name,
           @resultsDirectoryName = Results_Folder_Name
    FROM T_Job_Steps
         INNER JOIN T_Jobs
           ON T_Job_Steps.Job = T_Jobs.Job
    WHERE T_Job_Steps.Job = @jobNumber AND
          Step_Number = @stepNumber

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

    -- Lookup the MyEMSL Status URI
    -- We will only get a match if this job contains step tool ArchiveUpdate or DatasetArchive
    -- Furthermore, we won't get a row until after the ArchiveUpdate or DatasetArchive step successfully completes
    -- This URI will be used by the ArchiveVerify tool
    --
    SELECT TOP 1 @MyEMSLStatusURI = StatusU.URI_Path + CONVERT(varchar(16), MU.StatusNum),
                 @EUSInstrumentID = EUS_InstrumentID,
                 @EUSProposalID = EUS_ProposalID,
                 @EUSUploaderID = EUS_UploaderID
    FROM T_MyEMSL_Uploads MU
         INNER JOIN T_URI_Paths StatusU
           ON MU.StatusURI_PathID = StatusU.URI_PathID
    WHERE MU.Job = @jobNumber AND
          MU.StatusURI_PathID > 1
    ORDER BY MU.Entry_ID DESC

    If @MyEMSLStatusURI Like '%/status/%'
    Begin
        -- Need a URL of the form https://ingest.my.emsl.pnl.gov/myemsl/cgi-bin/status/3268638/xml
        Set @MyEMSLStatusURI = @MyEMSLStatusURI + '/xml'
    End


    ---------------------------------------------------
    -- Get job step parameters
    ---------------------------------------------------
    --
    Declare @stepParmSectionName varchar(32) = 'StepParameters'
    --
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Job', @jobNumber)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Step', @stepNumber)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepTool', @stepTool)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'ResultsDirectoryName', @resultsDirectoryName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'InputDirectoryName', @inputDirectoryName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'OutputDirectoryName', @outputDirectoryName)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'MyEMSL_Status_URI', @MyEMSLStatusURI)

    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'EUS_InstrumentID', @EUSInstrumentID)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'EUS_ProposalID', @EUSProposalID)
    INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'EUS_UploaderID', @EUSUploaderID)

    ---------------------------------------------------
    -- Get job parameters
    ---------------------------------------------------
    --
    -- to allow for more than one instance of a tool
    -- in a single script, look at parameters in sections
    -- that either are not locked to any step
    -- (step number is null) or are locked to the current step
    --
    INSERT INTO #ParamTab
    SELECT
        xmlNode.value('@Section', 'nvarchar(256)') Section,
        xmlNode.value('@Name', 'nvarchar(256)') Name,
        xmlNode.value('@Value', 'nvarchar(4000)') Value
    FROM
        T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
    WHERE
        T_Job_Parameters.Job = @jobNumber AND
        ((xmlNode.value('@Step', 'nvarchar(128)') IS NULL) OR (xmlNode.value('@Step', 'nvarchar(128)') = @stepNumber))
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error getting job parameters'
        goto Done
    end


    -- Get metadata for dataset if running the Dataset Info plugin or the Dataset Quality plugin
    -- The Dataset Info tool uses the Reporter_Mz_Min value to validate datasets with reporter ions
    -- The Dataset Quality tool creates file metadata.xml
    If @stepTool In ('DatasetInfo', 'DatasetQuality')
    Begin
        Declare @dataset varchar(128) = ''
        SELECT @dataset = Dataset
        FROM T_Jobs
        WHERE Job = @jobNumber

        EXEC GetMetadataForDataset @dataset
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetJobStepParams] TO [DDL_Viewer] AS [dbo]
GO
