/****** Object:  StoredProcedure [dbo].[AddRemoveRequestCartAssignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddRemoveRequestCartAssignment 
/****************************************************
**
**	Desc: 
**	Replaces existing component at given 
**  LC Cart component position with given component
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**  RequestIDList -- comma-delimited list of run request ID's
**  CartName      -- Name of the cart to assign (ignored in "Remove" mode)
**  Mode          -- "Add" or "Remove", depending on whether cart is to assigned to request or removed from request
**
**		Auth: grk
**		Date: 01/16/2008 grk - Initial Release (ticket http://prismtrac.pnl.gov/trac/ticket/715)
**    
**			01/28/2009 dac - Added "output" keyword to @message parameter
*****************************************************/
(
	@RequestIDList varchar(8000), 
	@CartName varchar(128),
	@Mode varchar(32) = 'Add', -- "Add" or "Remove"
	@message varchar(512) output
)
AS
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	-- does cart exist?
	---------------------------------------------------
	--
	declare @cartID int
	set @cartID = 0
	--
	if @Mode = 'Add'
	begin
		--
		SELECT @cartID = ID
		FROM T_LC_Cart
		WHERE (Cart_Name = @CartName)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to look up cart ID'
			goto Done
		end
		else 
		if @cartID = 0
		begin
			set @myError = 52117
			set @message = 'Could not resolve cart name to ID'
			goto Done
		end
	end
		else 
			set @cartID = 1 -- no cart

	---------------------------------------------------
	-- convert delimited list of requests into table
	---------------------------------------------------
	--
	declare @requests table (
		requestID int
	)
	--
	INSERT INTO @requests 
		(requestID)
	SELECT 
		convert(int, Item) 
	FROM  
		dbo.MakeTableFromList(@RequestIDList)
		
	---------------------------------------------------
	-- validate request ids
	---------------------------------------------------
	--
	declare @list varchar(512)
	set @list = ''
	--
	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN convert(varchar(14), requestID)
		ELSE ', ' + convert(varchar(14), requestID)
		END
	FROM
		@requests 
	WHERE 
		requestID NOT IN (SELECT ID FROM T_Requested_Run)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to validate request ID list'
		goto Done
	end
	--
	if @list <> ''
	begin
		set @myError = 51021
		set @message = 'The following request ID are not valid:' + @list
		goto Done
	end
	
	---------------------------------------------------
	-- update requests
	---------------------------------------------------
	--
	UPDATE 
		T_Requested_Run
	SET	RDS_Cart_ID = @cartID
	WHERE 
		ID in (SELECT requestID FROM @requests)	
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to update request table'
		goto Done
	end

	---------------------------------------------------
	-- exit
	---------------------------------------------------
	--
Done:
	return @myError
GO
GRANT EXECUTE ON [dbo].[AddRemoveRequestCartAssignment] TO [DMS_Instrument_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRemoveRequestCartAssignment] TO [DMS_LCMSNet_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRemoveRequestCartAssignment] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRemoveRequestCartAssignment] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRemoveRequestCartAssignment] TO [PNL\D3M580] AS [dbo]
GO
