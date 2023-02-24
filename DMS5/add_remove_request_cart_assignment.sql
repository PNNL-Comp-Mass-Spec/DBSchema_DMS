/****** Object:  StoredProcedure [dbo].[AddRemoveRequestCartAssignment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddRemoveRequestCartAssignment
/****************************************************
**
**	Desc: 
**		Replaces existing component at given LC Cart component position with given component
**
**		This procedure is used by method UpdateDMSCartAssignment in LcmsNetDmsTools.dll
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**		RequestIDList    -- comma-delimited list of run request ID's
**		CartName         -- Name of the cart to assign (ignored in "Remove" mode)
**		CartConfigName   -- Name of the cart config name to assign
**		Mode             -- "Add" or "Remove", depending on whether cart is to assigned to request or removed from request
**
**	Auth:	grk
**	Date:	01/16/2008 grk - Initial Release (ticket http://prismtrac.pnl.gov/trac/ticket/715)
**			01/28/2009 dac - Added "output" keyword to @message parameter
**			02/23/2017 mem - Added parameter @CartConfigName, which is used to populate column RDS_Cart_Config_ID
**
*****************************************************/
(
	@RequestIDList varchar(8000), 
	@CartName varchar(128),
	@CartConfigName varchar(128) = '',
	@Mode varchar(32) = 'Add', -- "Add" or "Remove"
	@message varchar(512) output
)
AS
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	
	Set @RequestIDList = IsNull(@RequestIDList, '')
	If @RequestIDList = ''
	Begin
		-- No Request IDs; nothing to do
		Goto Done
	End
	
	---------------------------------------------------
	-- Does cart exist?
	---------------------------------------------------
	--
	Declare @cartID int = 0
	Declare @cartConfigID int = null
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
		
		if @cartID = 0
		begin
			set @myError = 52117
			set @message = 'Could not resolve cart name to ID'
			goto Done
		end
		
		If IsNull(@CartConfigName, '') <> ''
		Begin
		
			SELECT @cartConfigID = Cart_Config_ID
			FROM T_LC_Cart_Configuration
			WHERE (Cart_Config_Name = @CartConfigName)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error trying to look up cart config name ID'
				goto Done
			end
			
			if @cartConfigID is null
			begin
				Declare @msg varchar(256) = 'Could not resolve cart config name "' + @CartConfigName + '" to ID for Request(s) ' + @RequestIDList
				exec PostLogEntry 'Error', @msg, 'AddRemoveRequestCartAssignment'
			end
		End
	end
	else
	Begin
		set @cartID = 1 -- no cart
		set @cartConfigID = null
	End
	
	---------------------------------------------------
	-- Convert delimited list of requests into table
	---------------------------------------------------
	--
	declare @requests table (
		requestID int
	)
	--
	INSERT INTO @requests( requestID )
	SELECT Value
	FROM dbo.udfParseDelimitedIntegerList ( @RequestIDList, ',' )
		
	---------------------------------------------------
	-- validate request ids
	---------------------------------------------------
	--
	Declare @list varchar(512) = ''
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
	UPDATE T_Requested_Run
	SET RDS_Cart_ID = @cartID,
	    RDS_Cart_Config_ID = @cartConfigID
	WHERE ID IN ( SELECT requestID
	              FROM @requests )
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
GRANT VIEW DEFINITION ON [dbo].[AddRemoveRequestCartAssignment] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRemoveRequestCartAssignment] TO [DMS_Instrument_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRemoveRequestCartAssignment] TO [DMS_LCMSNet_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddRemoveRequestCartAssignment] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddRemoveRequestCartAssignment] TO [Limited_Table_Write] AS [dbo]
GO
