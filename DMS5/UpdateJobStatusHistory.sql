/****** Object:  StoredProcedure [dbo].[UpdateJobStatusHistory] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateJobStatusHistory
/****************************************************
**
**	Desc: 
**		Appends new entries to T_Analysis_Job_Status_History,
**		summarizing the number of analysis jobs in each state
**      in T_Analysis_Job
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: mem
**		Date: 03/31/2005
**			  05/12/2005 mem - Changed default for @DatabaseName to be ''
**    
*****************************************************/
(
	@MinimumTimeIntervalHours integer = 1,	-- Set this to 0 to force the addition of new data to T_Analysis_Job_Status_History
	@DatabaseName varchar(64) = '',			-- Database containing T_Analysis_Job table; leave blank to use the current database
	@message varchar(128) = '' OUTPUT
)
AS
	Set NoCount On

	declare @myRowCount int
	declare @myError int
	set @myRowCount = 0
	set @myError = 0
	
	declare @TimeIntervalLastUpdateHours real
	declare @UpdateTable tinyint
	
	declare @S varchar(1024)
	
	set @message = ''
	
	if IsNull(@MinimumTimeIntervalHours, 0) = 0
		set @UpdateTable = 1
	else
	Begin

		SELECT @TimeIntervalLastUpdateHours = DateDiff(minute, MAX(Posting_Time), GetDate()) / 60.0
		FROM T_Analysis_Job_Status_History
		
		If IsNull(@TimeIntervalLastUpdateHours, @MinimumTimeIntervalHours) >= @MinimumTimeIntervalHours
			set @UpdateTable = 1
		else
			set @UpdateTable = 0
		
	End
	
	if @UpdateTable = 1
	Begin

		If Len(IsNull(@DatabaseName, '')) = 0
			Set @DatabaseName = DB_Name()
			
		Set @S = ''

		Set @S = @S + ' INSERT INTO T_Analysis_Job_Status_History (Posting_Time, Tool_ID, State_ID, Job_Count)'
		Set @S = @S + ' SELECT GETDATE() AS Posting_Time, Tool_ID, State_ID, Job_Count'
		Set @S = @S + ' FROM (	SELECT AJ.AJ_AnalysisToolID AS Tool_ID, '
		Set @S = @S + '   AJ.AJ_StateID AS State_ID, COUNT(AJ.AJ_jobID) AS Job_Count'
		Set @S = @S + '   FROM ' + @DatabaseName + '.dbo.T_Analysis_Job AS AJ'
		Set @S = @S + '   GROUP BY AJ.AJ_AnalysisToolID, AJ.AJ_StateID'
		Set @S = @S + '   ) LookupQ'
		Set @S = @S + ' ORDER BY Tool_ID, State_ID'
		
		Exec (@S)
		--
		SELECT @myError = @@error, @myRowCount = @@RowCount
		
		set @message = 'Appended ' + convert(varchar(9), @myRowCount) + ' rows to the Job Status History table'
	End
	else
		set @message = 'Update skipped since last update was ' + convert(varchar(9), Round(@TimeIntervalLastUpdateHours, 1)) + ' hours ago'
	
Done:

	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobStatusHistory] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateJobStatusHistory] TO [PNL\D3M578] AS [dbo]
GO
