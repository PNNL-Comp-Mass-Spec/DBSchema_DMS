/****** Object:  StoredProcedure [dbo].[manage_job_execution] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[manage_job_execution]
/****************************************************
**
**  Desc:
**      Updates parameters to new values for jobs in list
**      Meant to be called by job control dashboard program
**
**      Example contents of @parameters:
**          <root>
**            <operation>
**              <action>priority</action>
**              <value>5</value>
**            </operation>
**            <jobs>
**              <job>1563493</job>
**              <job>1563496</job>
**              <job>1563499</job>
**            </jobs>
**          </root>
**
**      Allowed values for action: state, priority, group
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**          05/08/2009 grk - Initial release
**          09/16/2009 mem - Now updating priority and processor group directly in this DB
**                         - Next, calls s_manage_job_execution to update the primary DMS DB
**          05/25/2011 mem - No longer updating priority in T_Job_Steps
**          06/01/2015 mem - Removed support for option @action = 'group' because we have deprecated processor groups
**          02/15/2016 mem - Added back support for @action = 'group'
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/05/2023 mem - Rename argument @result to @message
**
*****************************************************/
(
    @parameters text = '',
    @message varchar(4096) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @priority varchar(12)
    Declare @NewPriority int

    Declare @associatedProcessorGroup varchar(64)

    Declare @JobUpdateCount int

    ---------------------------------------------------
    -- Extract parameters from XML input
    ---------------------------------------------------

    Declare @paramXML xml

    Set @paramXML = @parameters

    ---------------------------------------------------
    -- Get action and value parameters
    ---------------------------------------------------

    Declare @action varchar(64) = ''

    SELECT @action = xmlNode.value('.', 'nvarchar(64)')
    FROM   @paramXML.nodes('//action') AS R(xmlNode)

    Declare @value varchar(512) = ''

    SELECT @value = xmlNode.value('.', 'nvarchar(512)')
    FROM   @paramXML.nodes('//value') AS R(xmlNode)

    ---------------------------------------------------
    -- Create temporary table to hold list of jobs
    -- and populate it from job list
    ---------------------------------------------------
    CREATE TABLE #Tmp_JobList (
        Job int
    )

    INSERT INTO #Tmp_JobList (Job)
    Select xmlNode.value('.', 'nvarchar(12)') Job
    FROM   @paramXML.nodes('//job') AS R(xmlNode)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error populating temporary job table'
        Return 51007
    End

    ---------------------------------------------------
    -- See if Priority or Processor Group needs to be updated
    ---------------------------------------------------

    If (@action = 'priority')
    Begin
        ---------------------------------------------------
        -- Immediately update priorities for jobs
        ---------------------------------------------------
        --

        Set @priority = @value
        Set @NewPriority = Cast(@priority as int)

        Set @JobUpdateCount = 0

        UPDATE T_Jobs
        SET Priority = @NewPriority
        FROM T_Jobs J
             INNER JOIN #Tmp_JobList JL
               ON J.Job = JL.Job
        WHERE J.Priority <> @NewPriority
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        Set @JobUpdateCount = @myRowCount

        If @JobUpdateCount > 0
        Begin
            Set @message = 'Job priorities changed: updated ' + Convert(varchar(12), @JobUpdateCount) + ' job(s) in T_Jobs'
            execute post_log_entry 'Normal', @message, 'manage_job_execution'
            Set @message = ''
        End
    End

    If (@action = 'group')
    Begin
        Set @associatedProcessorGroup = @value

        If @associatedProcessorGroup = ''
        Begin
            ---------------------------------------------------
            -- Immediately remove all processor group associations for jobs in #Tmp_JobList
            ---------------------------------------------------
            --
            DELETE T_Local_Job_Processors
            FROM T_Local_Job_Processors JP
                 INNER JOIN #Tmp_JobList JL
                   ON JL.Job = JP.Job
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            Set @JobUpdateCount = @myRowCount

            If @JobUpdateCount > 0
            Begin
                Set @message = 'Updated T_Local_Job_Processors; UpdateCount=0; InsertCount=0; DeleteCount=' + Convert(varchar(12), @JobUpdateCount)
                execute post_log_entry 'Normal', @message, 'manage_job_execution'
                Set @message = ''
            End
        End
        Else
        Begin
            ---------------------------------------------------
            -- Need to associate jobs with a specific processor group
            -- Given the complexity of the association, this needs to be done in DMS5,
            -- and this will happen when s_manage_job_execution is called
            ---------------------------------------------------
            Set @myError = 0
        End
    End

    If (@action = 'state')
    Begin
        If @value = 'Hold'
        Begin
            ---------------------------------------------------
            -- Immediately hold the requested jobs
            ---------------------------------------------------
            UPDATE T_Jobs
                SET State = 8                           -- 8=Holding
            FROM T_Jobs J INNER JOIN #Tmp_JobList JL ON J.Job = JL.Job
            WHERE J.State <> 8
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

        End
    End


    ---------------------------------------------------
    -- Call s_manage_job_execution to update the primary DMS DB
    ---------------------------------------------------

    exec @myError = s_manage_job_execution @parameters, @message output

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[manage_job_execution] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[manage_job_execution] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[manage_job_execution] TO [RBAC-Web_Analysis] AS [dbo]
GO
