/****** Object:  StoredProcedure [dbo].[AddUpdateUserOperations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create PROCEDURE AddUpdateUserOperations
/****************************************************
**
**	Desc:	Updates the user operations defined for the given user
**
**	Auth:	mem
**	Date:	06/05/2013 mem - Initial version
**    
*****************************************************/
(
	@UserID int,
	@OperationsList varchar(1024),			-- Comma separated separated list of operation names (see table T_User_Operations)
	@message varchar(512) = '' output
)
As
	Set nocount on
	
	Declare @myRowCount int
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0

	---------------------------------------------------
	-- Add/update operations defined for user
	---------------------------------------------------

	CREATE TABLE #Tmp_UserOperations (
		User_Operation varchar(64)
	)

	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error creating temporary user table'
		return 51008
	end

	---------------------------------------------------
	-- When populating #Tmp_UserOperations, ignore any user operations that
	-- do not exist in T_User_Operations
	---------------------------------------------------

	INSERT INTO #Tmp_UserOperations( User_Operation )
	SELECT CAST(Item AS varchar(64)) AS DMS_User_Operation
	FROM dbo.MakeTableFromList ( @OperationsList )
	WHERE CAST(Item AS varchar(64)) IN ( SELECT Operation
	                                     FROM T_User_Operations )


	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error parsing user operations list for user ' + Convert(varchar(12), @UserID)
		return 51009
	end
	
	---------------------------------------------------
	-- Add missing associations between operations and user 
	---------------------------------------------------
	--
	INSERT INTO T_User_Operations_Permissions( U_ID, Op_ID )
	SELECT @UserID, UO.ID
	FROM #Tmp_UserOperations NewOps
	     INNER JOIN T_User_Operations UO
	       ON NewOps.User_Operation = UO.Operation
	     LEFT OUTER JOIN T_User_Operations_Permissions UOP
	       ON UOP.U_ID = @UserID AND
	          UO.ID = UOP.Op_ID
	WHERE UOP.U_ID IS NULL

	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error adding operation permissions for user ' + Convert(varchar(12), @UserID)
		return 51083
	end

	---------------------------------------------------
	-- Remove extra associations 
	---------------------------------------------------
	--
	DELETE T_User_Operations_Permissions
	FROM #Tmp_UserOperations NewOps
	     INNER JOIN T_User_Operations UO
	       ON NewOps.User_Operation = UO.Operation
	     RIGHT OUTER JOIN T_User_Operations_Permissions UOP
	       ON UO.ID = UOP.Op_ID AND
	          UOP.U_ID = @UserID
	WHERE UOP.U_ID = @UserID AND
	      UO.ID IS NULL
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error removing operation permissions for user ' + Convert(varchar(12), @UserID)
		return 51084
	end

	
Done:
	return @myError

GO
