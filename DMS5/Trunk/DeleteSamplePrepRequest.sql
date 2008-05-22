/****** Object:  StoredProcedure [dbo].[DeleteSamplePrepRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.DeleteSamplePrepRequest
/****************************************************
**
**	Desc: 
**  Delete sample prep request
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	11/10/2005
**			01/04/2006 grk - added delete for aux info
**			05/16/2008 mem - Added optional parameter @callingUser; if provided, then will populate field System_Account in T_Sample_Prep_Request_Updates with this name (Ticket #674)
**    
*****************************************************/
(
	@requestID int,
    @message varchar(512) output,
	@callingUser varchar(128) = ''
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


	-- If @callingUser is defined, then update System_Account in T_Sample_Prep_Request_Updates
	If Len(@callingUser) > 0
		Exec AlterEnteredByUser 'T_Sample_Prep_Request_Updates', 'Request_ID', @requestID, @CallingUser, 
								@EntryDateColumnName='Date_of_Change', @EnteredByColumnName='System_Account'

	---------------------------------------------------
	-- Done
	---------------------------------------------------
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[DeleteSamplePrepRequest] TO [DMS_Ops_Admin]
GO
