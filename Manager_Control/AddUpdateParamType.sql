/****** Object:  StoredProcedure [dbo].[AddUpdateParamType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.AddUpdateParamType
/****************************************************
**
**	Desc: 
**	Updates existing parameter Type values in database
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	jds
**	Date:	04/01/2008
**			04/27/2009 mem - Added support for @mode = 'add'
**    
*****************************************************/
(
	@pID varchar(32) = '',
	@pName varchar(50) = '',
	@pPicklistName varchar(50),
	@pComment varchar(255),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	declare @pNameCurrent varchar(128)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @mode = IsNull(@mode, '??')
	Set @pID = IsNull(@pID, '')
	Set @pName = IsNull(@pName, '')
	
	if @mode <> 'add' and @mode <> 'update'
	Begin
		set @msg = 'Unsupported mode: ' + @mode 
		RAISERROR (@msg, 10, 1)
		return 51000
	End
	
	If @pName = ''
	Begin
		set @msg = 'Parameter name is empty; unable to continue'
		RAISERROR (@msg, 10, 1)
		return 51001
	End
		
	If @mode = 'add'
	Begin
		
		INSERT INTO T_ParamType (ParamName, PicklistName, Comment)
		VALUES (@pName, @pPicklistName, @pComment)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error adding new parameter to T_ParamType' 
			RAISERROR (@msg, 10, 1)
			return 51002
		end
	End
	
	
	If @mode = 'update'
	Begin
		---------------------------------------------------
		-- Update the T_Mgrs table
		---------------------------------------------------

		SELECT @pNameCurrent = ParamName
		FROM T_ParamType
		WHERE (ParamID = @pID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error looking for ID ' + @pID + ' in T_ParamType' 
			RAISERROR (@msg, 10, 1)
			return 51003
		end
		
		if @myRowCount = 0
		begin
			set @msg = 'Error updating T_ParamType; ParamID ' + @pID + ' not found'
			RAISERROR (@msg, 10, 1)
			return 51003
		end		
				
		UPDATE T_ParamType
		SET ParamName = @pName,
			PicklistName = @pPicklistName,
			Comment = @pComment
		WHERE (ParamID = @pID)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @msg = 'Error updating T_ParamType' 
			RAISERROR (@msg, 10, 1)
			return 51003
		end
		
		If @pNameCurrent <> @pName
			Set @message = 'Warning: Parameter renamed from "' + @pNameCurrent + '" to "' + @pName + '"'
	end
	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	return 0
GO
GRANT EXECUTE ON [dbo].[AddUpdateParamType] TO [DMSWebUser] AS [dbo]
GO
