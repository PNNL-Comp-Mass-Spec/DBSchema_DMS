/****** Object:  StoredProcedure [dbo].[UpdateCartParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateCartParameters
/****************************************************
**
**	Desc: 
**	Changes cart parameters 
**	for given requested run
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**    @mode      - type of update begin performed
**    @requestID - ID of scheduled run being updated
**    @newValue  - new vale that is being set, or value retured
**                 depending on mode
**    @message   - blank if update was successful,		
**                 description of error if not
**
**		Auth: grk
**		Date: 12/16/2003
**            2/27/2006 grk - added cart ID stuff
**            5/10/2006 grk - added verification of request ID
**    
*****************************************************/
	@mode varchar(32), -- 'CartName', 'RunStart', 'RunFinish', 'RunStatus', 'InternalStandard'
	@requestID int,
	@newValue varchar(512) output,
	@message varchar(512) output
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	declare @msg varchar(256)
	declare @dt datetime

	---------------------------------------------------
	-- verify that request ID is correct
	---------------------------------------------------
	declare @tmp int
	set @tmp = 0
	--
	SELECT @tmp = ID
	FROM T_Requested_Run
	WHERE (ID = @requestID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @msg = 'Error trying verify request ID'
		RAISERROR (@msg, 10, 1)
		return @myError
	end
	if @tmp = 0
	begin
		set @msg = 'Request ID not found'
		RAISERROR (@msg, 10, 1)
		return 52131
	end
	
	if @mode = 'CartName'
	begin
		---------------------------------------------------
		-- Resolve ID for LC Cart and update requested run table
		---------------------------------------------------

		declare @cartID int
		set @cartID = 0
		--
		SELECT @cartID = ID
		FROM T_LC_Cart
		WHERE (Cart_Name = @newValue)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error trying to look up cart ID'
		end
		else 
		if @cartID = 0
		begin
			set @myError = 52117
			set @msg = 'Could not resolve cart name to ID'
		end
		else
		begin
			UPDATE T_Requested_Run
			SET	RDS_Cart_ID = @cartID
			WHERE (ID = @requestID)	
			--	
			SELECT @myError = @@error, @myRowCount = @@rowcount
		end
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	if @mode = 'RunStatus'
	begin
		UPDATE T_Requested_Run
		SET	RDS_note = @newValue
		WHERE (ID = @requestID)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	if @mode = 'RunStart'
	begin
		if @newValue = ''
			set @dt = getdate()
		else
			set @dt = cast(@newValue as datetime)
	
		UPDATE T_Requested_Run
		SET	RDS_Run_Start = @dt
		WHERE (ID = @requestID)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	if @mode = 'RunFinish'
	begin		
		if @newValue = ''
			set @dt = getdate()
		else
			set @dt = cast(@newValue as datetime)
	
		UPDATE T_Requested_Run
		SET	 RDS_Run_Finish = @dt
		WHERE (ID = @requestID)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	if @mode = 'InternalStandard'
	begin
		UPDATE T_Requested_Run
		SET	RDS_Internal_Standard = @newValue
		WHERE (ID = @requestID)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount
	end


	---------------------------------------------------
	-- report any errors
	---------------------------------------------------
	if @myError <> 0 or @myRowCount = 0
	begin
		RAISERROR ('operation failed: "%s"', 10, 1, @mode)
		return 51310
	end	

	return 0

GO
GRANT EXECUTE ON [dbo].[UpdateCartParameters] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCartParameters] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCartParameters] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCartParameters] TO [PNL\D3M580] AS [dbo]
GO
