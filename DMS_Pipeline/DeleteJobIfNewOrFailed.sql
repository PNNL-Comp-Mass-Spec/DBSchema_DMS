/****** Object:  StoredProcedure [dbo].[DeleteJobIfNewOrFailed] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.DeleteJobIfNewOrFailed
/****************************************************
**
**	Desc:
**		Deletes the given job from T_Jobs if the state is New, Failed, or Holding
**		Does not delete the job if it has running job steps (though if the step started over 48 hours ago, ignore that job step)
**		This procedure is called by DeleteAnalysisJob in DMS5
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**			04/21/2017 mem - Initial release

*****************************************************/
(
    @job int,
	@callingUser varchar(128) = '',
	@message varchar(512)='' output,
	@previewMode tinyint = 0
)
As
	set nocount on
	
	Declare @myError int= 0
	Declare @myRowCount int = 0
 
	Set @message = ''
	Set @previewMode = IsNull(@previewMode, 0)
	
	If @previewMode > 0
	Begin
		If Exists (SELECT * FROM T_Jobs	
			       WHERE Job = @job AND
					   State IN (1, 5, 8) AND
					   NOT Job IN ( SELECT JS.Job
								    FROM T_Job_Steps JS
								    WHERE JS.Job = @job AND
									      JS.State = 4 AND
									      JS.Start >= DateAdd(hour, -48, GetDate()) 
								  ) )
		Begin
			SELECT 'To be deleted' as Action, *
			FROM T_Jobs
		End
		Else
		Begin
			If Exists (SELECT * FROM T_Jobs	WHERE Job = @job)
				SELECT 'Will not be deleted; wrong job state or running job steps' As Action, *
				FROM T_Jobs
				WHERE Job = @job
			Else
				SELECT 'Job not found in T_Jobs: ' + Cast(@job as Varchar(9)) As Action
		End
			
	End
	Else
	Begin
		
		---------------------------------------------------
		-- Delete the job, provided it's not active
		---------------------------------------------------
		--
		DELETE FROM T_Jobs	
		WHERE Job = @job AND
				State IN (1, 5, 8) AND
				NOT Job IN ( SELECT JS.Job
							FROM T_Job_Steps JS
							WHERE JS.Job = @job AND
								JS.State = 4 AND
								JS.Start >= DateAdd(hour, -48, GetDate()) 
							) 
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error deleting job ' + Cast(@job as varchar(9)) + ' from T_Jobs'
			goto Done
		end
	End
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DeleteJobIfNewOrFailed] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteJobIfNewOrFailed] TO [DMS_Ops_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteJobIfNewOrFailed] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteJobIfNewOrFailed] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteJobIfNewOrFailed] TO [Limited_Table_Write] AS [dbo]
GO
