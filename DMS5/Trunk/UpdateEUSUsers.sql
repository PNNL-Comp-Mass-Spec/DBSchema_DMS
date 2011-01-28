/****** Object:  StoredProcedure [dbo].[UpdateEUSUsers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateEUSUsers
/****************************************************
**
**	Desc: 
**	Changes atributes of EUS users
**	to given new value for given list of users
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/26/2006
**    
*****************************************************/
	@mode varchar(32), -- ''			-- Only allowed value is "site_status"
	@newValue varchar(512),
	@eusUserIDList varchar(2048)
As
	declare @delim char(1)
	set @delim = ','

	declare @done int
	declare @count int

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	--
	declare @id int
	--
	declare @tPos int
	set @tPos = 1
	declare @tFld varchar(128)

	---------------------------------------------------
	-- 
	---------------------------------------------------

	if @mode = 'site_status'
	begin -- mode 'site_status'

		---------------------------------------------------
		-- resolve site status name to ID
		declare @ssID int
		set @ssID = 0
		--
		SELECT @ssID = ID
		FROM T_EUS_Site_Status
		WHERE Name = @newValue	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @myError <> 0
		begin
			RAISERROR ('Error trying to resolve site status', 10, 1)
			return 51310
		end
		--
		if @ssID = 0
		begin
			RAISERROR ('Unrecognized site status', 10, 1)
			return 51311
		end

		---------------------------------------------------
		-- Update site status of all users in list
		--

		UPDATE T_EUS_Users
		SET Site_Status = @ssID
		WHERE PERSON_ID IN (
			SELECT * FROM dbo.MakeTableFromList(@eusUserIDList)
		)	
		--	
		SELECT @myError = @@error, @myRowCount = @@rowcount				
		--
		if @myError <> 0
		begin
			RAISERROR ('Error trying to ', 10, 1)
			return 51310
		end
	end  -- mode 'site_status'

	---------------------------------------------------
	-- 
	---------------------------------------------------


	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateEUSUsers] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateEUSUsers] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsers] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsers] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSUsers] TO [PNL\D3M580] AS [dbo]
GO
