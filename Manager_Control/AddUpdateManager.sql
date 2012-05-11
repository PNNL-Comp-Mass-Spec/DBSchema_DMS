/****** Object:  StoredProcedure [dbo].[AddUpdateManager] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[AddUpdateManager]
/****************************************************
**
**	Desc: 
**	Updates existing manager values in database
**
**	Return values: 0: success, otherwise, error code
**
**		Auth: jds
**		Date: 8/22/2007
**    
*****************************************************/
(
	@mID varchar(32) = '',
	@mName varchar(50) = '',
	@mControlFromWebsite varchar(32),
	@mode varchar(12) = 'add', -- or 'update'
	@message varchar(512) = '' output
)
As
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''
	
	declare @msg varchar(256)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- future

	---------------------------------------------------
	-- Update the T_Mgrs table
	---------------------------------------------------

	UPDATE T_Mgrs
    SET M_Name = @mName,
        M_ControlFromWebsite = @mControlFromWebsite
	WHERE (M_ID = @mID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 or @myRowCount <> 1
	begin
		set @msg = 'Error updating T_Mgrs.' 
		RAISERROR (@msg, 10, 1)
		return 51000
	end

	---------------------------------------------------
	-- 
	---------------------------------------------------

	return 0
GO
GRANT EXECUTE ON [dbo].[AddUpdateManager] TO [DMSWebUser] AS [dbo]
GO
