/****** Object:  StoredProcedure [dbo].[ManageJobExecution] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ManageJobExecution]
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in list
**      Meant to be called by job control dashboard program
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          07/09/2009 grk - Initial release
**          09/16/2009 mem - Updated to pass table #TAJ to UpdateAnalysisJobsWork
**                         - Updated to resolve job state defined in the XML with T_Analysis_State_Name
**          05/06/2010 mem - Expanded @settingsFileName to varchar(255)
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          03/31/2021 mem - Expand @organismName to varchar(128)
**
*****************************************************/
(
    @parameters text = '',
    @result varchar(4096) output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @jobCount int = 0
    Set @result = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'ManageJobExecution', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    --  Extract parameters from XML input
    ---------------------------------------------------
    --
    Declare @paramXML xml
    Set @paramXML = @parameters

    ---------------------------------------------------
    --  get action and value parameters
    ---------------------------------------------------
    
    Declare @action varchar(64)
    Set @action = ''

    SELECT @action = xmlNode.value('.', 'nvarchar(64)')
    FROM   @paramXML.nodes('//action') AS R(xmlNode)
    
    Declare @value varchar(512)
    Set @value = ''

    SELECT @value = xmlNode.value('.', 'nvarchar(512)')
    FROM   @paramXML.nodes('//value') AS R(xmlNode)
    
    ---------------------------------------------------
    -- Create temporary table to hold list of jobs
    -- and populate it from job list  
    ---------------------------------------------------
    CREATE TABLE #TAJ (
        Job int
    )

    INSERT INTO #TAJ (Job)
    SELECT xmlNode.value('.', 'nvarchar(12)') Job
    FROM   @paramXML.nodes('//job') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @result = 'Error populating temporary job table'
        return 51007
    End

    Set @jobCount = @myRowCount
    

    ---------------------------------------------------
    -- Set up default arguments 
    -- for calling UpdateAnalysisJobs
    ---------------------------------------------------
    --
    Declare @noChangeText varchar(32) = '[no change]'

    Declare @state varchar(32)                      = @noChangeText
    Declare @priority varchar(12)                   = @noChangeText
    Declare @comment varchar(512)                   = @noChangeText
    Declare @findText varchar(255)                  = @noChangeText
    Declare @replaceText varchar(255)               = @noChangeText
    Declare @assignedProcessor varchar(64)          = @noChangeText
    Declare @associatedProcessorGroup varchar(64)   = @noChangeText
    Declare @propagationMode varchar(24)            = @noChangeText
    Declare @parmFileName varchar(255)              = @noChangeText
    Declare @settingsFileName varchar(255)          = @noChangeText
    Declare @organismName varchar(128)              = @noChangeText
    Declare @protCollNameList varchar(4000)         = @noChangeText
    Declare @protCollOptionsList varchar(256)       = @noChangeText
    Declare @mode varchar(12)                       = 'update'
    Declare @message varchar(512)                   = ''
    Declare @callingUser varchar(128)               = ''

    ---------------------------------------------------
    -- Change affected calling arguments based on 
    -- command action and value
    ---------------------------------------------------
    --
    If (@action = 'state')
    Begin
        If @value = 'Hold'
            -- Holding
            SELECT @state = AJS_name
            FROM T_Analysis_State_Name
            WHERE (AJS_stateID = 8)
            
        If @value = 'Release'
        Begin
            -- Release (unhold)
            SELECT @state = AJS_name
            FROM T_Analysis_State_Name
            WHERE (AJS_stateID = 1)
        End
        
        If @value = 'Reset'
        Begin
            -- Reset
            -- For a reset, we still just Set the DMS state to "New"
            -- If the job was failed in the broker, it will get reset
            -- If it was on hold, then it will resume
            SELECT @state = AJS_name
            FROM T_Analysis_State_Name
            WHERE (AJS_stateID = 1)
        End
    End
    
    If(@action = 'priority')
    Begin
        Set @priority = @value
    End
    
    If(@action = 'group')
    Begin
        Set @associatedProcessorGroup = @value
    End

    ---------------------------------------------------
    -- Call UpdateAnalysisJobsWork function
    -- It uses #TAJ to determine which jobs to update
    ---------------------------------------------------
    --
    exec @myError = UpdateAnalysisJobsWork
        @state,
        @priority,
        @comment,
        @findText,
        @replaceText,
        @assignedProcessor,
        @associatedProcessorGroup,
        @propagationMode,
        @parmFileName,
        @settingsFileName,
        @organismName,
        @protCollNameList,
        @protCollOptionsList,
        @mode,
        @message output,
        @callingUser,
        @disableRaiseError=1

     ---------------------------------------------------
    -- Report success or error
    ---------------------------------------------------

    If @myError <> 0
    Begin
        If IsNull(@message, '') <> ''
            Set @result = 'Error: ' + @message + '; '
        Else
            Set @result = 'Unknown error calling UpdateAnalysisJobsWork; '
    End
    Else    
    Begin
        Set @result = @message
        
        If IsNull(@result, '') = ''
        Begin
            Set @result = 'Empty message returned by UpdateAnalysisJobsWork.  '
            Set @result = @result + 'The action was "' + @action + '".  '
            Set @result = @result + 'The value was "' + @value + '".  '
            Set @result = @result + 'There were ' + convert(varchar(12), @jobCount) + ' jobs in the list: '
        End
    End
    
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ManageJobExecution] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ManageJobExecution] TO [RBAC-Web_Analysis] AS [dbo]
GO
