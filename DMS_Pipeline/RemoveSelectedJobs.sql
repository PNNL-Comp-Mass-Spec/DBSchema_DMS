/****** Object:  StoredProcedure [dbo].[RemoveSelectedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE RemoveSelectedJobs
/****************************************************
**
**	Desc:
**  Delete jobs given in temp table #SJL 
**  that must be populated by the caller
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			02/19/2009 grk - initial release (Ticket #723)
**			02/26/2009 mem - Added parameter @LogDeletions
**          02/28/2009 grk - added logic to preserve record of successful shared results
**
*****************************************************/
(
	@infoOnly tinyint = 0,				-- 1 -> don't actually delete, just dump list of jobs that would have been
	@message varchar(512)='' output,
	@LogDeletions tinyint = 0			-- When 1, then logs each deleted job number in T_Log_Entries
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	Declare @Job int
	Declare @continue tinyint
		
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''
	Set @LogDeletions = IsNull(@LogDeletions, 0)

	---------------------------------------------------
	-- bail if no candidates found
 	---------------------------------------------------
	--
	declare @numJobs int
	set @numJobs = 0
	--
	SELECT @numJobs = COUNT(*) FROM #SJL
	--
 	if @numJobs = 0
		goto Done

	if @infoOnly > 0
	begin
		SELECT * FROM #SJL
	end 
	else
	begin -- <a>
 
		---------------------------------------------------
		-- preserve record of successfully completed
		-- shared results
 		---------------------------------------------------
 		--
 		-- for the jobs being deleted, finds all instances of
 		-- successfully completed results transfer steps that
 		-- were directly dependent upon steps that generated
 		-- shared results, and makes sure that their output folder
 		-- name is entered into the shared results table
 		--
		INSERT INTO T_Shared_Results
		(Results_Name)
		SELECT DISTINCT
			TS.Output_Folder_Name
		FROM   
			T_Job_Steps AS DS INNER JOIN 
			T_Job_Step_Dependencies AS JSD ON DS.Job = JSD.Job_ID AND DS.Step_Number = JSD.Step_Number INNER JOIN 
			T_Job_Steps AS TS ON JSD.Job_ID = TS.Job AND JSD.Target_Step_Number = TS.Step_Number
		WHERE
			DS.Step_Tool = 'Results_Transfer' AND
			DS.State = 5 AND
			TS.Shared_Result_Version > 0 AND
			NOT TS.Output_Folder_Name IN (SELECT Results_Name FROM T_Shared_Results) AND
			DS.Job IN (SELECT Job FROM #SJL)
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		 --
		if @myError <> 0
		begin
			set @message = 'Error preserving shared results'
			goto Done
		end

   		---------------------------------------------------
		-- delete job dependencies
		---------------------------------------------------
		--
		DELETE FROM T_Job_Step_Dependencies
		WHERE (Job_ID IN (SELECT Job FROM #SJL))
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		 --
		if @myError <> 0
		begin
			set @message = 'Error deleting T_Job_Step_Dependencies'
			goto Done
		end

   		---------------------------------------------------
		-- delete job parameters
		---------------------------------------------------
		--
		DELETE FROM T_Job_Parameters
		WHERE Job IN (SELECT Job FROM #SJL)
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		 --
		if @myError <> 0
		begin
			set @message = 'Error deleting T_Job_Parameters'
			goto Done
		end
 
   		---------------------------------------------------
		-- delete job steps
		---------------------------------------------------
		--
		DELETE FROM T_Job_Steps
		WHERE Job IN (SELECT Job FROM #SJL)
 		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		 --
		if @myError <> 0
		begin
			set @message = 'Error deleting T_Job_Steps'
			goto Done
		end

   		---------------------------------------------------
		-- Delete entries in T_Jobs
		---------------------------------------------------
		--
		If @LogDeletions <> 0
		Begin -- <b1>
		
			---------------------------------------------------
			-- Delete jobs one at a time, posting a log entry for each deleted job
			---------------------------------------------------
			
			Set @Job = 0
			
			SELECT @Job = MIN(Job)
			FROM #SJL
			
			Set @Job = IsNull(@Job, 0) - 1
			
			Set @Continue = 1
			While @Continue = 1
			Begin -- <c>
				SELECT TOP 1 @Job = Job
				FROM #SJL
				WHERE Job > @Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount = 0
					Set @Continue = 0
				Else
				Begin -- <d>
				
					DELETE FROM T_Jobs
					WHERE Job = @Job
 					--
					SELECT @myError = @@error, @myRowCount = @@rowcount
					--
					if @myError <> 0
					begin
						set @message = 'Error deleting job ' + Convert(varchar(17), @Job) + ' from T_Jobs'
						goto Done
					end
					
					Set @message = 'Deleted job ' + Convert(varchar(17), @Job) + ' from T_Jobs'
					Exec PostLogEntry 'Normal', @message, 'RemoveSelectedJobs'
					
				End -- </d>
				
			End -- </c>
			
		End -- </b1>
		Else
		Begin -- <b2>
		
			---------------------------------------------------
			-- Delete in bulk
			---------------------------------------------------
		
			DELETE FROM T_Jobs
			WHERE Job IN (SELECT Job FROM #SJL)
 			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error deleting T_Jobs'
				goto Done
			end
			
		End -- </b2>
 	end -- </a>

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RemoveSelectedJobs] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RemoveSelectedJobs] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[RemoveSelectedJobs] TO [PNL\D3M580] AS [dbo]
GO
