/****** Object:  StoredProcedure [dbo].[GetJobStepParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetJobStepParams
/****************************************************
**
**	Desc:
**    Get job step parameters for given job step
**    Into temporary table created by caller
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	Date:	09/08/2009 grk - initial release (http://prismtrac.pnl.gov/trac/ticket/746)
**			08/30/2013 mem - Added MyEMSL_Status_URI
**			01/04/2016 mem - Added EUS_InstrumentID, EUS_ProposalID, and EUS_UploaderID
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

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	--
	declare @stepTool varchar(64)
	declare @inputFolderName varchar(128)
	declare @outputFolderName varchar(128)
	declare @resultsFolderName varchar(128)	
	declare @MyEMSLStatusURI varchar(128)
	
	declare @EUSInstrumentID int
	declare @EUSProposalID varchar(10)
	declare @EUSUploaderID int
	
	set @stepTool = ''
	set @inputFolderName = ''
	set @outputFolderName = ''
	set @resultsFolderName = ''
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
	       @inputFolderName = Input_Folder_Name,
	       @outputFolderName = Output_Folder_Name,
	       @resultsFolderName = Results_Folder_Name
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
	SELECT TOP 1 @MyEMSLStatusURI = StatusU.URI_Path + CONVERT(varchar(16), MU.StatusNum) + '/xml',
	             @EUSInstrumentID = EUS_InstrumentID,
	             @EUSProposalID = EUS_ProposalID,
	             @EUSUploaderID = EUS_UploaderID
	FROM T_MyEMSL_Uploads MU
	     INNER JOIN T_URI_Paths StatusU
	       ON MU.StatusURI_PathID = StatusU.URI_PathID
	WHERE MU.Job = @jobNumber AND
	      MU.StatusURI_PathID > 1
	ORDER BY MU.Entry_ID DESC

	---------------------------------------------------
	-- Get job step parameters
	---------------------------------------------------
	--
	declare @stepParmSectionName varchar(32)
	set @stepParmSectionName = 'StepParameters'
	--
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Job', @jobNumber)
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'Step', @stepNumber)
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'StepTool', @stepTool)
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'ResultsFolderName', @resultsFolderName)
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'InputFolderName', @inputFolderName)
	INSERT INTO #ParamTab ([Section], [Name], Value) VALUES (@stepParmSectionName, 'OutputFolderName', @outputFolderName)
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
	-- that either are not locked to any setp 
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

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	--
	return @myError

GO
