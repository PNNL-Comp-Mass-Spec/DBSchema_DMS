/****** Object:  StoredProcedure [dbo].[FindExistingJobsForRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE FindExistingJobsForRequest
/****************************************************
**
**	Desc: 
**    Check how many existing jobs already exist that
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**		Auth: grk
**		Date: 12/5/2005
**			  04/07/2006 grk - eliminated job to request map table
**    
*****************************************************/
	@requestID int,
	@message varchar(512) output
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
		
	SELECT
		T_Analysis_Job.AJ_jobID AS Job, 
		T_Analysis_State_Name.AJS_name AS State, 
		T_Analysis_Job.AJ_requestID AS Request, 
		T_Analysis_Job.AJ_created AS Created, 
		T_Analysis_Job.AJ_start AS Start, 
		T_Analysis_Job.AJ_finish AS Finish
	FROM
		T_Analysis_Job INNER JOIN
		GetRunRequestExistingJobListTab(@requestID) M ON M.job = T_Analysis_Job.AJ_jobID INNER JOIN
		T_Analysis_State_Name ON T_Analysis_Job.AJ_StateID = T_Analysis_State_Name.AJS_stateID

Done:
	RETURN @myError



GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_Guest]
GO
GRANT EXECUTE ON [dbo].[FindExistingJobsForRequest] TO [DMS_User]
GO
