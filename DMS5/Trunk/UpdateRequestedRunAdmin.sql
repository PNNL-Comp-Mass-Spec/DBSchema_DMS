/****** Object:  StoredProcedure [dbo].[UpdateRequestedRunAdmin] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateRequestedRunAdmin
/****************************************************
**
**	Desc: 
**	Requested run admin operations 
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 03/09/2010
**    
*****************************************************/
	@requestList text,
	@mode varchar(32), -- 
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = ''
As
	SET NOCOUNT ON 

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	SET @message = ''


	-----------------------------------------------------------
	-- temp table to hold list of requests
	-----------------------------------------------------------
	--
	CREATE TABLE #TMP (
		Item VARCHAR(128),
		Status VARCHAR(32) NULL,
		Origin VARCHAR(32) NULL
	)
	SET @xml = @requestList
	--
	INSERT INTO #TMP
		( Item )
	select
		xmlNode.value('@i', 'nvarchar(256)') Item
	FROM @xml.nodes('//r') AS R(xmlNode)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to convert list'
		GOTO Done
	end

	-----------------------------------------------------------
	-- validate request list
	-----------------------------------------------------------
	--
	 UPDATE
		#TMP
	 SET
		Status = RDS_Status,
		Origin = RDS_Origin
	 FROM
		#TMP
		INNER JOIN dbo.T_Requested_Run ON Item = CONVERT(VARCHAR(12), dbo.T_Requested_Run.ID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error trying to get status'
		GOTO done
	end
	
	IF EXISTS (SELECT * FROM #TMP WHERE Status IS NULL)
	BEGIN
		SET @myError = 51012
		set @message = 'There were invalid request IDs'
		GOTO done
	end

	IF EXISTS (SELECT * FROM #TMP WHERE not Status IN ('Active', 'Inactive'))
	BEGIN
		SET @myError = 51013
		set @message = 'Cannot change requests that are in status other than "Active" or "Inactive"'
		GOTO done
	end

	IF EXISTS (SELECT * FROM #TMP WHERE not Origin = 'user')
	BEGIN
		SET @myError = 51013
		set @message = 'Cannot change requests were not entered by user'
		GOTO done
	end

	-----------------------------------------------------------
	-- 
	-----------------------------------------------------------
	--
	IF @mode = 'Active' OR @mode = 'Inactive'
	BEGIN
		UPDATE 
			T_Requested_Run
		SET 
			RDS_Status = @mode
		WHERE 
			ID IN (SELECT CONVERT(INT, Item) FROM #TMP)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to update status'
			GOTO done
		end
		GOTO Done
	END

	-----------------------------------------------------------
	-- 
	-----------------------------------------------------------
	--
	IF @mode = 'delete'
	BEGIN
		DELETE FROM  
			T_Requested_Run
		WHERE 
			ID IN (SELECT CONVERT(INT, Item) FROM #TMP)		
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error trying to delete requests'
			GOTO done
		end
		GOTO Done
	END

	-----------------------------------------------------------
	-- 
	-----------------------------------------------------------
	--
Done:
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateRequestedRunAdmin] TO [DMS2_SP_User] AS [dbo]
GO
