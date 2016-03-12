/****** Object:  StoredProcedure [dbo].[ReportSequestWarnings] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.ReportSequestWarnings
/****************************************************
**
**	Desc:	Displays or e-mails a list of Sequest clusters
**			 that have non-zero Evaluation_Code values in T_Job_Steps
**
**			@JobFinishThresholdHours is used to only return recent problems
**
**
**	Auth:	mem
**			12/10/2009 mem - Initial Version
**			12/11/2009 mem - Now returning the SQL Query in the e-mail
**			12/14/2009 mem - Now displaying Job and Finish as the first two columns
**    
*****************************************************/
(
	@IncludeWarningsInReport tinyint = 0,	-- When 0, then will only report jobs / send an e-mail if the Evaluation_Code column has an error bit set.  When 1, will show stats for all jobs in T_Job_Steps that have a non-zero Evaluation_Code value
	@JobFinishThresholdHours int = 24,		-- Will include jobs that have finished within this many hours of the present time
	@SendEmail tinyint = 0,					-- When 1, then will send an e-mail to the addesses specified by @EmailAddressList if any jobs have a warning
	@EmailAddressList varchar(4000) = 'matthew.monroe@pnl.gov',
	@message varchar(512) = '' output
)
As

	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @DateThreshold datetime
	declare @body varchar(1024)
	declare @SqlQuery varchar(1024)
	
	declare @SepChar char(1)

	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	--
	Set @IncludeWarningsInReport = IsNull(@IncludeWarningsInReport, 0)
	Set @JobFinishThresholdHours = IsNull(@JobFinishThresholdHours, 24)
	Set @SendEmail = IsNull(@SendEmail, 0)
	Set @EmailAddressList = IsNull(@EmailAddressList, '')
	
	If @EmailAddressList = ''
		Set @SendEmail = 0

	If @JobFinishThresholdHours <= 0
		Set @JobFinishThresholdHours = 365*24
	
	-- Define the date threshold
	Set @DateThreshold = DateAdd(hour, -@JobFinishThresholdHours, GetDate())
	
	-- Define the separator character as a space
	set @SepChar = ' '
	
	If @IncludeWarningsInReport = 0
	Begin -- <a1>
		-----------------------------------------------------------
		-- Only report errors
		-----------------------------------------------------------
		
		If exists (SELECT * FROM V_Sequest_Cluster_Warnings WHERE Finish >= @DateThreshold)
		Begin -- <b1>
			if @SendEmail = 0
			Begin -- <c1>
				SELECT Job,
				       Finish,
				       Processor,
				       Evaluation_Code AS Code,
				       Warning,
				       Evaluation_Message,
				       Dataset,
				       Tool
				FROM DMS_Pipeline.dbo.V_Sequest_Cluster_Warnings
				WHERE Finish >= @DateThreshold
				ORDER BY Processor, Finish
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

			End -- </c1>
			Else
			Begin -- <c2>
				set @body = 'One or more Sequest Clusters reported an active node count lower than the expected value.' + CHAR(13) + CHAR(10)
				set @body = @body + 'See also: SELECT * FROM V_Sequest_Cluster_Warnings WHERE Finish >= ''' + Convert(varchar(48), @DateThreshold, 20) + '''' + CHAR(13) + CHAR(10)
				
				set @SqlQuery = 'SELECT Job, CONVERT(VARCHAR(19), Finish, 20) AS Finish, Convert(varchar(14), Processor) AS Processor, CONVERT(VARCHAR(4), Evaluation_Code) AS Code, Warning, Convert(varchar(50), Evaluation_Message) AS Evaluation_Message, Convert(varchar(64), Dataset) AS Dataset, Convert(varchar(12), Tool) AS Tool FROM DMS_Pipeline.dbo.V_Sequest_Cluster_Warnings WHERE Finish >= ''' + Convert(varchar(48), @DateThreshold, 20) + ''' ORDER BY Processor, Finish'
				
				exec msdb.dbo.sp_send_dbmail 
					@profile_name = 'DMS_Mail',
					@recipients = @EmailAddressList,
					@subject ='SEQUEST Warnings',
					@body = @body,
					@query = @SqlQuery,
					@exclude_query_output = 1,
					@append_query_error = 1,
					@attach_query_result_as_file = 0,
					@query_result_separator = @SepChar
			End -- </c2>
		End -- </b1>
	End -- </a1>
	Else
	Begin -- <a2>
		-----------------------------------------------------------
		-- Report errors and warnings
		-----------------------------------------------------------


		If exists (SELECT * FROM dbo.V_Job_Steps AS JS WHERE Tool LIKE '%sequest%' AND Evaluation_Code <> 0 AND Finish >= @DateThreshold)
		Begin -- <b1>
			if @SendEmail = 0
			Begin -- <c1>
				SELECT Processor,
				       Evaluation_Code AS Code,
				       Evaluation_Message,
				       Job,
				       Finish,
				       Dataset,
				       Tool
				FROM dbo.V_Job_Steps AS JS
				WHERE Tool LIKE '%sequest%' AND
				      Evaluation_Code <> 0 AND
				      Finish >= @DateThreshold
				ORDER BY Processor, Finish
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount

			End -- </c1>
			Else
			Begin -- <c2>
				set @body = 'One or more Sequest Clusters reported an error or warning code.' + CHAR(13) + CHAR(10)
				set @body = @body + 'See also: SELECT * FROM dbo.V_Job_Steps WHERE Evaluation_Code <> 0 AND Finish >= ''' + Convert(varchar(48), @DateThreshold, 20) + '''' + CHAR(13) + CHAR(10)
				
				set @SqlQuery = 'SELECT Job, CONVERT(VARCHAR(19), Finish, 20) AS Finish, Convert(varchar(14), Processor) AS Processor, CONVERT(VARCHAR(4), Evaluation_Code) AS Code, Convert(varchar(50), Evaluation_Message) AS Evaluation_Message, Convert(varchar(64), Dataset) AS Dataset, Convert(varchar(12), Tool) AS Tool FROM DMS_Pipeline.dbo.V_Job_Steps AS JS WHERE Tool LIKE ''%sequest%'' AND Evaluation_Code <> 0 AND Finish >= ''' + Convert(varchar(48), @DateThreshold, 20) + ''' ORDER BY Processor, Finish'
				
				exec msdb.dbo.sp_send_dbmail 
					@profile_name = 'DMS_Mail',
					@recipients = @EmailAddressList,
					@subject ='SEQUEST Warnings',
					@body = @body,
					@query = @SqlQuery,
					@exclude_query_output = 1,
					@append_query_error = 1,
					@attach_query_result_as_file = 0,
					@query_result_separator = @SepChar
			End -- </c2>
		End -- </b1>
	
	
	End -- </a2>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ReportSequestWarnings] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportSequestWarnings] TO [PNL\D3M578] AS [dbo]
GO
