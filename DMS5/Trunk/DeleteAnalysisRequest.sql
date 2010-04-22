/****** Object:  StoredProcedure [dbo].[DeleteAnalysisRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteAnalysisRequest
/****************************************************
**
**	Desc: 
**  Delete analysis request if it has not be used
**  to make any jobs
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 10/13/2004
**			  04/07/2006 grk - eliminated job to request map table
**    
*****************************************************/
(
	@requestID int,
    @message varchar(512) output
)
As	
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	---------------------------------------------------
	-- Does request exist?
	---------------------------------------------------
	--
	declare @tempID int
	set @tempID = 0
	--
	SELECT 
		@tempID = T_Analysis_Job_Request.AJR_requestID
	FROM
		T_Analysis_Job_Request
 	WHERE
		T_Analysis_Job_Request.AJR_requestID = @requestID
	--
	SELECT @myError = @@error
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for job request'
		goto Done
	end

	if @tempID = 0
	begin
		set @message = 'Could not find analysis request'
		set @myError = 9
		goto Done
	end

	---------------------------------------------------
	-- look up  number of jobs made from request
	---------------------------------------------------
	--
	declare @num int
	set @num = 1
	--
	SELECT @num = count(*)
	FROM         T_Analysis_Job
	WHERE     (AJ_requestID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error looking for job request'
		goto Done
	end

	if @num <> 0
	begin
		set @message = 'Cannot delete an analysis request that has jobs made from it'
		set @myError = 10
		goto Done
	end

	
	---------------------------------------------------
	-- delete the analysis request
	---------------------------------------------------
	--
	DELETE FROM T_Analysis_Job_Request
	WHERE     (AJR_requestID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error deleting analysis request'
		goto Done
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
Done:
	return @myError



GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisRequest] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DeleteAnalysisRequest] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisRequest] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DeleteAnalysisRequest] TO [PNL\D3M580] AS [dbo]
GO
