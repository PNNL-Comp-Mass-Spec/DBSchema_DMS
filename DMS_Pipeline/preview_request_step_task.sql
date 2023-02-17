/****** Object:  StoredProcedure [dbo].[preview_request_step_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[preview_request_step_task]
/****************************************************
**
**  Desc: Previews the next step task that would be returned for a given processor
**
**  Auth:   mem
**          12/05/2008 mem
**          01/15/2009 mem - Updated to only display the job info if a job is assigned (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**          08/23/2010 mem - Added parameter @infoOnly
**          05/18/2017 mem - Call s_get_default_remote_info_for_manager to retrieve the @remoteInfo XML for @processorName
**                           Pass this to request_step_task_xml
**                           (s_get_default_remote_info_for_manager is a synonym for the stored procedure in the Manager_Control DB)
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @processorName varchar(128),
    @jobCountToPreview int = 10,    -- The number of jobs to preview
    @jobNumber int = 0 output,        -- Job number assigned; 0 if no job available
    @parameters varchar(max) = '' output, -- job step parameters (in XML)
    @message varchar(512) = '' output,
    @infoOnly tinyint = 1            -- 1 to preview the assigned task; 2 to preview the task and see extra status messages
)
AS
    set nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Set @infoOnly = IsNull(@infoOnly, 1)
    If @infoOnly < 1
        Set @infoOnly = 1

    Declare @remoteInfo varchar(900)

    Exec s_get_default_remote_info_for_manager @processorName, @remoteInfoXML = @remoteInfo output

    Exec request_step_task_xml @processorName,
                            @jobNumber = @jobNumber output,
                            @parameters = @parameters output,
                            @message = @message output,
                            @infoonly = @infoOnly,
                            @JobCountToPreview=@JobCountToPreview,
                            @remoteInfo = @remoteInfo

    If Exists (Select * FROM T_Jobs WHERE Job = @JobNumber)
    Begin
        SELECT @jobNumber AS JobNumber,
               Dataset,
               @ProcessorName AS Processor,
               @parameters AS Parameters,
               @message AS Message
        FROM T_Jobs
        WHERE Job = @JobNumber
    End
    Else
    Begin
        SELECT @message as Message
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[preview_request_step_task] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[preview_request_step_task] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[preview_request_step_task] TO [Limited_Table_Write] AS [dbo]
GO
