/****** Object:  StoredProcedure [dbo].[CrossCheckJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.CrossCheckJobParameters
/****************************************************
**
**	Desc: Compares the data in #Job_Steps to existing data in T_Job_Steps
**		  to look for incompatibilities
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	grk
**			02/03/2009 grk - initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**			03/11/2009 mem - Now including Old/New step tool and Old/New Signatures if differences are found (Ticket #725, http://prismtrac.pnl.gov/trac/ticket/725)
**			01/06/2011 mem - Added parameter @IgnoreSignatureMismatch
**    
*****************************************************/
(
	@job int,
	@message varchar(512) output,
	@IgnoreSignatureMismatch tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- cross-check steps against parameter effects
	---------------------------------------------------
	--
	declare @jobS varchar(12)
	set @jobS = CONVERT(varchar(12), @job)
	--
	SELECT @message = @message +
		CASE WHEN (OJS.Shared_Result_Version = NJS.Shared_Result_Version) THEN '' ELSE 
			' step ' + CONVERT(varchar(12), OJS.Step_Number) + ' Shared_Result_Version ' + 
			'(' + CONVERT(varchar(12), OJS.Shared_Result_Version) + '|' + CONVERT(varchar(12), NJS.Shared_Result_Version) + ');'  
			END +
		
		CASE WHEN (OJS.Step_Tool = NJS.Step_Tool) THEN '' ELSE 
			' step ' + CONVERT(varchar(12), OJS.Step_Number) + ' Step_Tool ' + 
			'(' + CONVERT(varchar(12), OJS.Step_Tool) + '|' + CONVERT(varchar(12), NJS.Step_Tool) + ');'  
			END +
			
		CASE WHEN (OJS.Signature = NJS.Signature ) OR @IgnoreSignatureMismatch > 0 THEN '' ELSE 
			' step ' + CONVERT(varchar(12), OJS.Step_Number)  + ' Signature ' + 
			'(' + CONVERT(varchar(12), OJS.Signature) + '|' + CONVERT(varchar(12), NJS.Signature) + ');'  
			END
			
		-- CASE WHEN (OJS.Output_Folder_Name = NJS.Output_Folder_Name) THEN '' ELSE 
		--  ' step ' + CONVERT(varchar(12), OJS.Step_Number) + ' Output_Folder_Name;'  END	
		
	FROM T_Job_Steps OJS
	     INNER JOIN #Job_Steps NJS
	       ON OJS.Job = NJS.Job AND
	          OJS.Step_Number = NJS.Step_Number
	WHERE ((NOT (OJS.Signature IS NULL)) OR
	       (NOT (NJS.Signature IS NULL)))

	if @message <> ''
	begin
		set @myError = 99
		set @message = 'Parameter mismatch:' + @message
	end

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CrossCheckJobParameters] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CrossCheckJobParameters] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CrossCheckJobParameters] TO [PNL\D3M580] AS [dbo]
GO
