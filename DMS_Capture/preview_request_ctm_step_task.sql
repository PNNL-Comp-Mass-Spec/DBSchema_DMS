/****** Object:  StoredProcedure [dbo].[preview_request_ctm_step_task] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[preview_request_ctm_step_task]
/****************************************************
**
**  Desc:
**      Previews the next step task that would be returned for a given processor
**
**  Auth:   mem
**          01/06/2011 mem
**          07/26/2012 mem - Now looking up "perspective" for the given manager and then passing @serverPerspectiveEnabled into request_ctm_step_task
**          02/03/2023 bcg - Use the synonym for Manager_Control.V_Mgr_Params instead of a local view wrapping the synonym
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**          03/06/2023 bcg - Rename the synonym used to access Manager_Control.V_Mgr_Params
**          04/01/2023 mem - Rename procedures and functions
**          06/07/2023 mem - No longer look up "perspective" for the given manager, since the Capture Task Manager 
**                           does not customize the value of @serverPerspectiveEnabled when calling request_ctm_step_task
**
*****************************************************/
(
    @processorName varchar(128),
    @jobCountToPreview int = 10,        -- The number of jobs to preview
    @jobNumber int = 0 output,          -- Job number assigned; 0 if no job available
    @parameters varchar(max)='' output, -- job step parameters (in XML)
    @message varchar(512)='' output,
    @infoOnly tinyint = 1               -- 0 or 1 to preview the assigned task; 2 to preview the task and see extra status messages; 3 to dump candidate tables and variables
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @infoOnly = IsNull(@infoOnly, 1)

    If @infoOnly < 1
        Set @infoOnly = 1

    /*
     * Deprecated in June 2023
     *

    Declare @serverPerspectiveEnabled tinyint = 0
    Declare @perspective varchar(64) = ''

    -- Lookup the value for "perspective" for this manager in the manager control DB
    SELECT @perspective = Parameter_Value
    FROM s_mc_v_mgr_params
    WHERE (Manager_Name = @processorName) AND (Parameter_Name = 'perspective')

    If IsNull(@perspective, '') = ''
    Begin
        Set @message = 'The "Perspective" parameter was not found for manager "' + @processorName + '" in V_Mgr_Params'
    End

    If @perspective = 'server'
    Begin
        Set @serverPerspectiveEnabled = 1
    End

    */

    Exec request_ctm_step_task
                    @processorName,
                    @jobNumber =         @jobNumber output,
                    @message =           @message output,
                    @infoonly =          @infoOnly,
                    @JobCountToPreview = @JobCountToPreview
                    -- Deprecated: @serverPerspectiveEnabled = @serverPerspectiveEnabled

    If Exists (Select * FROM T_Tasks WHERE Job = @JobNumber)
        SELECT @jobNumber AS JobNumber,
               Dataset,
               @ProcessorName AS Processor,
               @parameters AS Parameters,
               @message AS Message
        FROM T_Tasks
        WHERE Job = @JobNumber
    Else
        SELECT @message as Message


    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:

    --
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[preview_request_ctm_step_task] TO [DDL_Viewer] AS [dbo]
GO
