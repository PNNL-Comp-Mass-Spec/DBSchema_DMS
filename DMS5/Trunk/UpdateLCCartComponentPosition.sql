/****** Object:  StoredProcedure [dbo].[UpdateLCCartComponentPosition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateLCCartComponentPosition
/****************************************************
**
**	Desc: 
**	Replaces existing component at given 
**  LC Cart component position with given component
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 07/03/2008     - (ticket http://prismtrac.pnl.gov/trac/ticket/604)
**    
*****************************************************/
	@mode varchar(32), -- 'replace'
	@PositionID int,
	@ComponentID int, 
	@comment varchar(512),
    @message varchar(512) output,
   	@callingUser varchar(128) = ''
As
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	---------------------------------------------------
	-- resolve user
	---------------------------------------------------
	--
	set @callingUser = IsNull(@callingUser, '')
	--
	declare @userID int
	set @userID = 0
	--
	SELECT @userID = ID
	FROM	T_Users
	WHERE U_PRN = @callingUser
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error resolving user ID'
		return 51000
	end
	
	---------------------------------------------------
	-- get component that is currently at given cart position
	-- (if any)
	---------------------------------------------------
	--
	declare @oldComponentID int
	set @oldComponentID = 0
	-- 
	SELECT
		@oldComponentID =  ID
	FROM
		T_LC_Cart_Components
	WHERE
		Component_Position = @PositionID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting currently installed component'
		return 51000
	end

	---------------------------------------------------
	-- make sure new and old components aren't the same
	---------------------------------------------------
	--
	if @ComponentID = @oldComponentID
	begin
		set @message = 'New component must be different than existing component'
		return 51002
	end

	---------------------------------------------------
	-- make sure new component is valid
	---------------------------------------------------
	--
	declare @tmp varchar(64)
	set @tmp = ''
	--
	SELECT	
		@tmp =   T_LC_Cart_Component_Type.Type
	FROM
		T_LC_Cart_Component_Type INNER JOIN
		T_LC_Cart_Components ON T_LC_Cart_Component_Type.ID = T_LC_Cart_Components.Type
	WHERE
		T_LC_Cart_Components.ID = @ComponentID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting information about component'
		return 51001
	end
	--
	if @tmp = ''
	begin
		set @message = 'Component ID is not valid'
		return 51002
	end
	---------------------------------------------------
	-- make sure new component's type 
	-- matches position's type
	---------------------------------------------------
	--
	declare @typ varchar(64)
	set @typ = ''
	--
	SELECT
		@typ = T_LC_Cart_Component_Type.Type
	FROM
		T_LC_Cart_Component_Postition INNER JOIN
		T_LC_Cart_Positions ON T_LC_Cart_Component_Postition.Position_ID = T_LC_Cart_Positions.ID INNER JOIN
		T_LC_Cart_Component_Type ON T_LC_Cart_Positions.Component_Type = T_LC_Cart_Component_Type.ID
   WHERE
		T_LC_Cart_Component_Postition.ID = @PositionID
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting information about position allowed component type'
		return 51001
	end
	--
	if @tmp <> @typ
	begin
		set @message = 'Component type is "' + @tmp + '", but cart position only accepts "' + @typ + '"'
		return 51002
	end

	---------------------------------------------------
	-- make updates where they are needed 
	---------------------------------------------------

	---------------------------------------------------
	-- get any history with open date for old component
	---------------------------------------------------
	--
	declare @oldComponentHistorySeqID int
	set @oldComponentHistorySeqID = 0
	--
	SELECT
		@oldComponentHistorySeqID = ID
	FROM
		T_LC_Cart_Component_History
	WHERE
		(Cart_Component = @oldComponentID) AND 
		(Ending_Date IS NULL)	
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting open history for old component'
		return 51011
	end

	---------------------------------------------------
	-- get any history with open date for new component
	---------------------------------------------------
	--
	declare @newComponentHistorySeqID int
	set @newComponentHistorySeqID = 0
	--
	SELECT
		@newComponentHistorySeqID = ID
	FROM
		T_LC_Cart_Component_History
	WHERE
		(Cart_Component = @ComponentID) AND 
		(Ending_Date IS NULL)	
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error getting open history for new component'
		return 51012
	end

	---------------------------------------------------
	-- action timestamp
	---------------------------------------------------
	declare @stamp datetime
	set @stamp = getdate()

	---------------------------------------------------
	-- set up transaction
	---------------------------------------------------
	--
	declare @transName varchar(32)
	set @transName = 'ReplaceLCCartComponent'
	--
	begin transaction @transName

	---------------------------------------------------
	-- close any open history date for old component
	---------------------------------------------------
	
	if @oldComponentHistorySeqID <> 0
	begin --<och>
		UPDATE
			T_LC_Cart_Component_History
		SET
			Ending_Date = @stamp
		WHERE
			(ID = @oldComponentHistorySeqID)	
	end --<och>

	if @newComponentHistorySeqID <> 0
	begin --<nch>
		UPDATE
			T_LC_Cart_Component_History
		SET
			Ending_Date = @stamp
		WHERE
			(ID = @newComponentHistorySeqID)	
	end --<nch>

	---------------------------------------------------
	-- make new history entry for new component
	---------------------------------------------------
	--
	INSERT INTO T_LC_Cart_Component_History (
		Operator,
		Action,
		Starting_Date,
		Ending_Date,
		COMMENT,
		Cart_Component,
		Component_Position
	) VALUES (  
		@userID,
		'Replace',
		@stamp,
		NULL,
		@comment,
		@ComponentID,
		@PositionID
	)
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error making entry for new component'
		return 51003
	end


	---------------------------------------------------
	-- clear position reference from old component
	---------------------------------------------------
	
	if @oldComponentID <> 0
	begin
		UPDATE
			T_LC_Cart_Components
		SET
			Component_Position = NULL, 
			Starting_Date = NULL
		WHERE
			(ID = @oldComponentID)	
   		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			rollback transaction @transName
			set @message = 'Error clearing old component position reference'
			return 51009
		end
	end

	---------------------------------------------------
	-- set position reference for new component 
	-- to given cart position
	---------------------------------------------------
	--
	UPDATE
		T_LC_Cart_Components
	SET
		Component_Position = @PositionID,
		Starting_Date = @stamp
	WHERE
		ID = @ComponentID
   	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		rollback transaction @transName
		set @message = 'Error setting new component position reference'
		return 51004
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	commit transaction @transName

	return @myError
GO
GRANT EXECUTE ON [dbo].[UpdateLCCartComponentPosition] TO [DMS2_SP_User]
GO
