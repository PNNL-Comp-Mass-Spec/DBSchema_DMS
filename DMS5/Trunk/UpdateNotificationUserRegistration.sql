/****** Object:  StoredProcedure [dbo].[UpdateNotificationUserRegistration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateNotificationUserRegistration
/****************************************************
**
**  Desc:
**  Sets user registration for notification entities
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 04/03/2010
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
	@PRN varchar(15),
	@Name varchar(64),
	@RequestedRunBatch varchar(4),
	@AnalysisJobRequest varchar(4),
	@SamplePrepRequest varchar(4),
	@Dataset varchar(4),
	@mode varchar(12) = 'update',
	@message varchar(512) output,
	@callingUser varchar(128) = ''
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0

	set @message = ''
	
	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	DECLARE @userID INT
	SET @userID = 0
	--
	SELECT
		@userID = ID
	FROM
		T_Users
	WHERE
		U_PRN = @PRN
	--
	IF @userID = 0
	BEGIN
		SET @message = 'User PRN "' + @PRN + '" is not valid'
		SET @myError = 15
		GOTO Done
	END

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	DECLARE @entityTypeID int
	DECLARE @entityTypeParm VARCHAR(15)

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	SET @entityTypeID = 1
	SET @entityTypeParm = @RequestedRunBatch
	--
	IF @entityTypeParm = 'Yes'
	BEGIN
	  IF NOT EXISTS ( SELECT
						*
					  FROM
						T_Notification_Entity_User
					  WHERE
						User_ID = @userID
						AND Entity_Type_ID = @entityTypeID ) 
		BEGIN
		  INSERT  INTO dbo.T_Notification_Entity_User
				  ( User_ID, Entity_Type_ID )
		  VALUES
				  ( @userID, @entityTypeID )
		END 
	END
	IF @entityTypeParm = 'No'
	BEGIN
		DELETE FROM
			T_Notification_Entity_User
		WHERE
			User_ID = @userID
			AND Entity_Type_ID = @entityTypeID
	END

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	SET @entityTypeID = 2
	SET @entityTypeParm = @AnalysisJobRequest
	--
	IF @entityTypeParm = 'Yes'
	BEGIN
	  IF NOT EXISTS ( SELECT
						*
					  FROM
						T_Notification_Entity_User
					  WHERE
						User_ID = @userID
						AND Entity_Type_ID = @entityTypeID ) 
		BEGIN
		  INSERT  INTO dbo.T_Notification_Entity_User
				  ( User_ID, Entity_Type_ID )
		  VALUES
				  ( @userID, @entityTypeID )
		END 
	END
	IF @entityTypeParm = 'No'
	BEGIN
		DELETE FROM
			T_Notification_Entity_User
		WHERE
			User_ID = @userID
			AND Entity_Type_ID = @entityTypeID
	END

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	SET @entityTypeID = 3
	SET @entityTypeParm = @SamplePrepRequest
	--
	IF @entityTypeParm = 'Yes'
	BEGIN
	  IF NOT EXISTS ( SELECT
						*
					  FROM
						T_Notification_Entity_User
					  WHERE
						User_ID = @userID
						AND Entity_Type_ID = @entityTypeID ) 
		BEGIN
		  INSERT  INTO dbo.T_Notification_Entity_User
				  ( User_ID, Entity_Type_ID )
		  VALUES
				  ( @userID, @entityTypeID )
		END 
	END
	IF @entityTypeParm = 'No'
	BEGIN
		DELETE FROM
			T_Notification_Entity_User
		WHERE
			User_ID = @userID
			AND Entity_Type_ID = @entityTypeID
	END


	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	SET @entityTypeID = 4
	SET @entityTypeParm = @Dataset
	--
	IF @entityTypeParm = 'Yes'
	BEGIN
	  IF NOT EXISTS ( SELECT
						*
					  FROM
						T_Notification_Entity_User
					  WHERE
						User_ID = @userID
						AND Entity_Type_ID = @entityTypeID ) 
		BEGIN
		  INSERT  INTO dbo.T_Notification_Entity_User
				  ( User_ID, Entity_Type_ID )
		  VALUES
				  ( @userID, @entityTypeID )
		END 
	END
	IF @entityTypeParm = 'No'
	BEGIN
		DELETE FROM
			T_Notification_Entity_User
		WHERE
			User_ID = @userID
			AND Entity_Type_ID = @entityTypeID
	END


	---------------------------------------------------
	-- 
	---------------------------------------------------
	--

Done:
	return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateNotificationUserRegistration] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateNotificationUserRegistration] TO [Limited_Table_Write] AS [dbo]
GO
