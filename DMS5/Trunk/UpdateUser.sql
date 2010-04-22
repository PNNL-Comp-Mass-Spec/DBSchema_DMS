/****** Object:  StoredProcedure [dbo].[UpdateUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateUser 
	(
		@hid varchar(50),
		@name varchar(50),
		@email varchar(64),
		@domain varchar(32),
		@netid varchar(32),
		@active varchar(1)
	)
AS
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @msg varchar(256)
	
	BEGIN TRANSACTION

	UPDATE    T_Users
	SET       U_Name = @name, U_email = @email, U_domain = @domain, U_netid = @netid, U_active = @active
	WHERE     (U_HID = @hid)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0 or @myRowCount = 0
		begin
			ROLLBACK TRANSACTION
			set @msg = 'Update operation failed: "' + @hid + '"'
			RAISERROR (@msg, 10, 1)
			return 51004
		end
		--
		if @myRowCount > 1
		begin
			ROLLBACK TRANSACTION
			set @msg = 'Updated more than one row: "' + @hid + '"'
			RAISERROR (@msg, 10, 1)
			return 51005
		end
		
	COMMIT TRANSACTION
	RETURN 0


GO
GRANT EXECUTE ON [dbo].[UpdateUser] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUser] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUser] TO [PNL\D3M580] AS [dbo]
GO
