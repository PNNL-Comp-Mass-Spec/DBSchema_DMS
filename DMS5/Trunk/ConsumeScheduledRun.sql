/****** Object:  StoredProcedure [dbo].[ConsumeScheduledRun] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure ConsumeScheduledRun
/****************************************************
**
**	Desc:
**	Associates given requested run with the given dataset
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	
**
**		Auth: grk
**		Date: 2/13/2003
**		1/5/2002    grk - Added stuff for Internal Standard and cart parameters
**      3/1/2004    grk - Added validation for experiments matching between request and dataset
**      10/12/2005  grk - Added stuff to copy new work package and proposal fields.
**      1/13/2006   grk - Handling for new blocking columns in request and history tables.
**      1/17/2006   grk - Handling for new EUS tracking columns in request and history tables.
**		04/08/2008  grk - Added handling for separation field (Ticket #658)
**		03/26/2009  grk - Added MRM transition list attachment (Ticket #727)
**		02/26/2010  grk - merged T_Requested_Run_History with T_Requested_Run
**    
*****************************************************/
	@datasetID int,
	@requestID int,
	@message varchar(255) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''


	---------------------------------------------------
	-- Validate that experiments match
	---------------------------------------------------
	
	-- get experiment ID from dataset
	--
	declare @experimentID int
	set @experimentID = 0
	--
	SELECT   @experimentID = Exp_ID
	FROM T_Dataset
	WHERE Dataset_ID = @datasetID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to look up experiment for dataset'
		RAISERROR (@message, 10, 1)
		return 51085
	end

	-- get experiment ID from scheduled run
	--
	declare @reqExperimentID int
	set @reqExperimentID = 0
	--
	SELECT   @reqExperimentID = Exp_ID
	FROM T_Requested_Run
	WHERE ID = @requestID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to look up experiment for request'
		RAISERROR (@message, 10, 1)
		return 51086
	end
	
	-- validate that experiments match
	--
	if @experimentID <> @reqExperimentID
	begin
		set @message = 'Experiment in dataset does not match with one in scheduled run'
		RAISERROR (@message, 10, 1)
		return 51072
	end

	---------------------------------------------------
	-- start transaction
	---------------------------------------------------	
	
	declare @transName varchar(32)
	set @transName = 'ConsumeScheduledRun'
	begin transaction @transName

	UPDATE
		T_Requested_Run
	SET
		DatasetID = @datasetID, 
		RDS_Status = 'Completed'
	WHERE
		ID = @requestID	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Failed to update dataset field in request'
		rollback transaction @transName
		return 51009
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	commit transaction @transName
	return 0

GO
GRANT EXECUTE ON [dbo].[ConsumeScheduledRun] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ConsumeScheduledRun] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ConsumeScheduledRun] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ConsumeScheduledRun] TO [PNL\D3M580] AS [dbo]
GO
