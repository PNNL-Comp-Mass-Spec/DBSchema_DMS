/****** Object:  StoredProcedure [dbo].[DeleteSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DeleteSamplePrepRequest
/****************************************************
**
**	Desc: 
**  Delete sample prep request
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 11/10/2005
**             1/04/2006 grk added delete for aux info
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
	-- Start transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'DeleteSamplePrepRequest'
	begin transaction @transName

	
	---------------------------------------------------
	-- remove any referring entries from update table
	---------------------------------------------------
	--
	DELETE FROM T_Sample_Prep_Request_Updates
	WHERE     (Request_ID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error removing update history of request'
		goto Done
	end


	---------------------------------------------------
	-- remove any references from experiments
	---------------------------------------------------
	--
	declare @num int
	set @num = 1
	--
	UPDATE T_Experiments
	SET EX_sample_prep_request_ID = 0
	WHERE (EX_sample_prep_request_ID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error removing experiment references to request'
		goto Done
	end

	---------------------------------------------------
	-- Delete all entries from auxiliary value table
	-- for the sample prep request
	---------------------------------------------------

	DELETE FROM T_AuxInfo_Value
	WHERE (Target_ID = @requestID) AND 
	(
		AuxInfo_ID IN
		(
		SELECT Item_ID
		FROM V_Aux_Info_Definition_wID
		WHERE (Target = 'SamplePrepRequest')
		)
	)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error deleting aux info'
		goto Done
	end
	
	---------------------------------------------------
	-- delete the sample prep request itself
	---------------------------------------------------
	--
	DELETE FROM T_Sample_Prep_Request
	WHERE     (ID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error deleting sample prep request'
		goto Done
	end


	---------------------------------------------------
	-- if we got here, complete transaction
	---------------------------------------------------
	commit transaction @transName

	---------------------------------------------------
	-- 
	---------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[DeleteSamplePrepRequest] TO [DMS_Ops_Admin]
GO
