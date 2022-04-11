/****** Object:  StoredProcedure [dbo].[CreateAnalysisJobFromRequestList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAnalysisJobFromRequestList]
/****************************************************
**
**  Desc: 
**      Creates analysis jobs for a given list of
**      analysis job requests
**
**  Auth:   grk
**  Date:   09/17/2007 grk - Initial version (Ticket #534)
**          09/20/2007 mem - Now checks for existing jobs if @mode <> 'add'
**          02/27/2009 mem - Expanded @comment to varchar(512)
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          08/01/2012 mem - Now sending @specialProcessing to AddAnalysisJobGroup
**                         - Updated @datasetList to be varchar(max)
**          09/25/2012 mem - Expanded @organismDBName and @organismName to varchar(128)
**          04/08/2015 mem - Now parsing the job request list using udfParseDelimitedIntegerList
**          04/11/2022 mem - Expand @protCollNameList to varchar(4000)
**
*****************************************************/
(
    @mode varchar(32) = 'preview',                  -- 'add' or 'preview'
    @jobRequestList varchar(4096),                  -- Comma separated list of analysis job requests
    @priority int = 2,                              -- Priority
    @associatedProcessorGroup varchar(64) = '',     -- Processor group name
    @propagationMode varchar(24) = 'Export'         -- 'Export' or 'No Export'
)
As
    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @requestID int
    Declare @toolName varchar(64)
    Declare @parmFileName varchar(255)
    Declare @settingsFileName varchar(255)
    Declare @organismDBName varchar(128)
    Declare @organismName varchar(128)
    Declare @datasetList varchar(max)
    Declare @comment varchar(512)
    Declare @specialProcessing varchar(512)
    Declare @ownerPRN varchar(32)
    Declare @protCollNameList varchar(4000)
    Declare @protCollOptionsList varchar(256)
    Declare @message varchar(512)
    
    -------------------------------------------------
    -- Temporary table to hold job requests
    -------------------------------------------------

    CREATE TABLE #TRL (
        requestID int,
        toolName varchar(64),
        parmFileName varchar(255),
        settingsFileName varchar(255),
        organismDBName varchar(128),
        organismName varchar(128),
        datasetList varchar(max),
        comment varchar(512),
        specialProcessing varchar(512),
        ownerPRN varchar(32),
        protCollNameList varchar(4000),
        protCollOptionsList varchar(256),
        stateName varchar(24)
    )    
    --    
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --

    -------------------------------------------------
    -- Get particulars for requests in list
    -------------------------------------------------
    INSERT INTO #TRL (
        requestID,
        toolName,
        parmFileName,
        settingsFileName,
        organismDBName,
        organismName,
        datasetList,
        comment,
        specialProcessing,
        ownerPRN,
        protCollNameList,
        protCollOptionsList,
        stateName
    )
    SELECT
      AJR_requestID,
      AJR_analysisToolName,
      AJR_parmFileName,
      AJR_settingsFileName,
      AJR_organismDBName,
      AJR_organismName,
      AJR_datasets,
      AJR_comment,
      AJR_specialProcessing,
      requestor,
      protCollNameList,
      protCollOptionsList,
      State
    FROM   
      V_Analysis_Job_Request_Entry
    WHERE AJR_requestID IN (SELECT Value FROM dbo.udfParseDelimitedIntegerList(@jobRequestList, ','))
    --    
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --

    -------------------------------------------------
    -- Temp table to hold results for each request
    -------------------------------------------------
    CREATE TABLE #XRS (
        requestID int,
        result int,
        description varchar(512)
    )
    --    
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --

    -------------------------------------------------
    -- Verify all requests in "new" state
    -------------------------------------------------
    INSERT INTO #XRS (requestID, result, description)
    SELECT requestID, -1, 'Request not in state new; unable to process'
    FROM #TRL INNER JOIN
         dbo.T_Analysis_Job_Request AJR ON #TRL.requestID = AJR.AJR_requestID
    WHERE AJR.AJR_state <> 1
    --    
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --

    If @myRowCount > 0
    Begin
        -- Remove the invalid rows from #TRL
        DELETE #TRL
        FROM #TRL INNER JOIN 
             #XRS ON #TRL.requestID = #XRS.requestID
             
        -- Continue only if @mode is <> 'add'
        if @mode = 'add'
            Goto ReportResults
    End
        

    -------------------------------------------------
    -- Cycle through each request,
    -- and make a bunch of jobs for it
    -------------------------------------------------

    Declare @done int
    Declare @result int
    Declare @ExistingJobMsg varchar(128)
    Declare @ExistingJobCount int

    set @done = 0
    set @result = 0
    set @requestID = 0
    
    while @done = 0
    begin -- <a>
        -------------------------------------------------
        -- Add group of jobs for request
        -------------------------------------------------

        -------------------------------------------------
        -- Get next request to process
        -------------------------------------------------
        SELECT TOP 1 @requestID = requestID
        FROM #TRL 
        WHERE requestID > @requestID
        ORDER BY requestID
        --    
        SELECT @myError = @@error, @myRowCount = @@rowcount        
        
        -------------------------------------------------
        -- done, if no more requests
        -------------------------------------------------
        If @myRowCount = 0
            set @done = 1
        Else
        Begin -- <b>
            -------------------------------------------------
            -- Get key information from request
            -------------------------------------------------
            SELECT
                @toolName =  toolName,
                @parmFileName = parmFileName,
                @settingsFileName = settingsFileName,
                @organismDBName = organismDBName,
                @organismName = organismName,
                @datasetList = datasetList,
                @comment = comment,
                @specialProcessing = specialProcessing,
                @ownerPRN =  ownerPRN,
                @protCollNameList = protCollNameList,
                @protCollOptionsList = protCollOptionsList
            FROM #TRL
            WHERE requestID = @requestID
            --    
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --

            -------------------------------------------------
            -- Check for existing jobs
            -------------------------------------------------
            Set @ExistingJobCount = 0
            
            SELECT @ExistingJobCount = COUNT(*)
            FROM dbo.T_Analysis_Job
            WHERE AJ_RequestID = @requestID

            If @ExistingJobCount > 0
            Begin
                If @ExistingJobCount = 1
                    Set @ExistingJobMsg = 'Note: 1 job'
                Else
                    Set @ExistingJobMsg = 'Note: ' + Convert(varchar(12), @ExistingJobCount) + ' jobs'
                Set @ExistingJobMsg = @ExistingJobMsg + ' found matching this request''s parameters'
            End
            Else
                Set @ExistingJobMsg = ''
            

            -------------------------------------------------
            -- Use it to make a bunch of jobs
            -------------------------------------------------
            exec @result = AddAnalysisJobGroup
                                @datasetList=@datasetList,
                                @priority=@priority,
                                @toolName=@toolName,
                                @parmFileName=@parmFileName,
                                @settingsFileName=@settingsFileName,
                                @organismDBName=@organismDBName,
                                @organismName=@organismName,
                                @protCollNameList=@protCollNameList,
                                @protCollOptionsList=@protCollOptionsList,
                                @ownerPRN=@ownerPRN,
                                @comment=@comment,
                                @specialProcessing=@specialProcessing,
                                @requestID=@requestID,
                                @associatedProcessorGroup=@associatedProcessorGroup,
                                @propagationMode=@propagationMode,
                                @removeDatasetsWithJobs='Y',
                                @mode=@mode, 
                                @message=@message output

            Set @message = IsNull(@message, '')
            If @ExistingJobCount > 0
                Set @message = @ExistingJobMsg + '; ' + @message
            
            -------------------------------------------------
            -- Keep track of results
            -------------------------------------------------
            INSERT INTO #XRS
                (requestID,result,description)
            VALUES     (@requestID, @result, @message)
        end -- </b>

            
    end -- </a>

ReportResults:

    -------------------------------------------------
    -- Report results
    -------------------------------------------------
    SELECT * 
    FROM #XRS
    ORDER BY requestID
    
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CreateAnalysisJobFromRequestList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[CreateAnalysisJobFromRequestList] TO [DMS_Analysis] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateAnalysisJobFromRequestList] TO [Limited_Table_Write] AS [dbo]
GO
