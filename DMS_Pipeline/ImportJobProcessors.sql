/****** Object:  StoredProcedure [dbo].[ImportJobProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ImportJobProcessors
/****************************************************
**
**	Desc:
**    get list of jobs and associated processors
**    and count of associated groups that are enabled for general processing
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			05/26/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			01/17/2009 mem - Removed Insert operation for T_Local_Job_Processors, since SyncJobInfo now populates T_Local_Job_Processors (Ticket #716, http://prismtrac.pnl.gov/trac/ticket/716)
**			06/27/2009 mem - Now removing entries from T_Local_Job_Processors only if the job is complete or not present in T_Jobs; if a job is failed but still in T_Jobs, then the entry is not removed from T_Local_Job_Processors
**			07/01/2010 mem - No longer logging message "Updated T_Local_Job_Processors; DeleteCount=" each time T_Local_Job_Processors is updated
**			06/01/2015 mem - No longer deleting rows in T_Local_Job_Processors since we have deprecated processor groups
**			02/15/2016 mem - Re-enabled support for processor groups, but altered logic to wait for 2 hours before deleting completed jobs
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	if @bypassDMS <> 0
		goto Done

	---------------------------------------------------
	-- Remove job-processor associations 
	-- from jobs that completed at least 2 hours ago
	---------------------------------------------------

	DELETE FROM T_Local_Job_Processors
	WHERE Job IN ( SELECT Job
	               FROM T_Jobs
	               WHERE State = 4 AND
	                     DATEDIFF(HOUR, Finish, GETDATE()) > 2 )
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		set @message = 'Error removing job-processor associations'
		goto Done
	end
     	
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ImportJobProcessors] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ImportJobProcessors] TO [PNL\D3M578] AS [dbo]
GO
