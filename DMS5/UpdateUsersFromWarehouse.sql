/****** Object:  StoredProcedure [dbo].[UpdateUsersFromWarehouse] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateUsersFromWarehouse
/****************************************************
**
**	Desc: 
**		Updates user information in T_Users using linked server SQLSRVPROD02
**
**		Defined the linked server using:
**			EXEC sp_addlinkedserver 'SQLSRVPROD02', '', 'SQLNCLI', 'SQLSRVPROD02,915'
**			EXEC sp_addlinkedsrvlogin 'SQLSRVPROD02', 'FALSE', NULL, 'PRISM', '5GigYawn'
**
**	Return values: 0: success, otherwise, error code
**
**	Auth: 	mem
**	Date: 	03/25/2013 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512)='' output
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
	

	BEGIN TRY 

		----------------------------------------------------------
		-- Create a temporary table to track the user information 
		-- stored in the data warehouse
		----------------------------------------------------------
		--
		CREATE TABLE #Tmp_UserInfo (
			ID int not null,
			[Name] varchar(128) NULL,
			Email varchar(128) NULL,
			Domain varchar(64) NULL,
			NetworkLogin varchar(64) NULL,
			Active varchar(8) NOT NULL,
			UpdateRequired tinyint NOT NULL
		)
		
		CREATE CLUSTERED INDEX IX_Tmp_UserInfo_ID ON #Tmp_UserInfo (ID)

		----------------------------------------------------------
		-- Obtain info for staff
		----------------------------------------------------------
		--
		INSERT INTO #Tmp_UserInfo( ID,
		                           [Name],
		                           Email,
		                           Domain,
		                           NetworkLogin,
		                           Active,
		                           UpdateRequired )
		SELECT U.ID,
		       PREFERRED_NAME_FM,
		       INTERNET_EMAIL_ADDRESS,
		       NETWORK_DOMAIN,
		       NETWORK_ID,
		       IsNull(ACTIVE_SW, 'N') AS Active,
		       0 AS UpdateRequired
		FROM T_Users U
		     INNER JOIN SQLSRVPROD02.opwhse.dbo.VW_PUB_BMI_EMPLOYEE Src
		       ON U.U_HID = 'H' + Src.HANFORD_ID
		WHERE U.U_update = 'Y'
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		
		----------------------------------------------------------
		-- Obtain info for associates
		----------------------------------------------------------
		--
		INSERT INTO #Tmp_UserInfo( ID,
		                           [Name],
		                           Email,
		                           Domain,
		                           NetworkLogin,
		                           Active,
		                           UpdateRequired )
		SELECT U.ID,
		       Src.last_name + ', ' + Src.pref_first_name,
		       Src.internet_address,
		       NetworkInfo.NETWORK_DOMAIN,
		       NetworkInfo.NETWORK_ID,
		       IsNull(Src.pnl_maintained_sw, 'N') AS Active,
		       0 AS UpdateRequired
		FROM T_Users U
		     INNER JOIN SQLSRVPROD02.opwhse.dbo.vw_pub_pnnl_associate Src
		       ON U.U_HID = 'H' + Src.HANFORD_ID
		     LEFT OUTER JOIN SQLSRVPROD02.opwhse.dbo.VW_PUB_BMI_NT_ACCT_TBL NetworkInfo
		       ON Src.hanford_id = NetworkInfo.HANFORD_ID
		     LEFT OUTER JOIN #Tmp_UserInfo Target
		       ON U.ID = Target.ID
		WHERE U.U_update = 'Y' AND
		      Target.ID IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		----------------------------------------------------------
		-- Look for users that need to be udpated
		----------------------------------------------------------
		--
		UPDATE #Tmp_UserInfo
		SET UpdateRequired = 1
		FROM T_Users U
		     INNER JOIN #Tmp_UserInfo Src
		       ON U.ID = Src.ID
		WHERE IsNull(U.U_Name, '') <> IsNull(Src.Name, IsNull(U.U_Name, '')) OR
		      IsNull(U.U_email, '') <> IsNull(Src.Email, IsNull(U.U_email, '')) OR
		      IsNull(U.U_domain, '') <> IsNull(Src.Domain, IsNull(U.U_domain, '')) OR
		      IsNull(U.U_netid, '') <> IsNull(Src.NetworkLogin, IsNull(U.U_netid, '')) OR
		      IsNull(U.U_active, '') <> IsNull(Src.Active, IsNull(U.U_active, ''))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

		If @infoOnly = 0
		Begin
			BEGIN TRANSACTION

				----------------------------------------------------------
				-- Perform the update
				----------------------------------------------------------
				--
				UPDATE T_Users
				SET U_Name = IsNull(Src.Name, U.U_Name),
				    U_email = IsNull(Src.Email, U.U_email),
				    U_domain = IsNull(Src.Domain, U.U_domain),
				    U_netid = IsNull(Src.NetworkLogin, U.U_netid),
				    U_active = Src.Active,
				    Last_Affected = GetDate()
				FROM T_Users U
				     INNER JOIN #Tmp_UserInfo Src
				       ON U.ID = Src.ID
				WHERE UpdateRequired = 1
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount > 0
				Begin
					Set @message = 'Updated ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.CheckPlural(@myRowCount, 'user', 'users') + ' using the PNNL Data Warehouse'
					
					Exec PostLogEntry 'Normal', @message, 'UpdateUsersFromWarehouse'
				End
				
			COMMIT TRANSACTION

		End
		Else
		Begin
			----------------------------------------------------------
			-- Preview the updates
			----------------------------------------------------------
			--
			SELECT U.U_Name,    Src.Name AS Name_New,
			       U.U_email,   Src.Email AS EMail_New,
			       U.U_domain,  Src.Domain AS Domain_New,
			       U.U_netid,   Src.NetworkLogin AS NetworkLogin_New,
			       U.U_active,  Src.Active AS Active_New
			FROM T_Users U
			     INNER JOIN #Tmp_UserInfo Src
			       ON U.ID = Src.ID
			WHERE UpdateRequired = 1
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		End

		----------------------------------------------------------
		-- Look for users marked for auto-update who were not found in either of the data warehouse views
		----------------------------------------------------------
		--
		DECLARE @tblUserProblems TABLE ( ID      int NOT NULL,
		                                 Warning varchar(128) )
		
		INSERT INTO @tblUserProblems (ID, Warning)
		SELECT U.ID,
		       'User not found in the Data Warehouse'
		FROM T_Users U
		     LEFT OUTER JOIN #Tmp_UserInfo Src
		       ON U.ID = Src.ID
		WHERE U.U_update = 'Y' AND
		      Src.ID IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
			

		If @infoOnly = 0 And @myRowCount > 0
		Begin
			Set @message = dbo.CheckPlural(@myRowCount, 'User', 'Users') + ' not found in the Data Warehouse: '
			
			SELECT @message = @message + IsNull(U.U_HID, '??? Undefined U_HID for ID=' + Convert(varchar(12), U.ID) + ' ???') + ', '
			FROM T_Users U
				    INNER JOIN @tblUserProblems M
				    ON U.ID = M.ID
			ORDER BY U.ID
			
			-- Remove the trailing comma
			Set @message = RTrim(@message)
			Set @message = Left(@message, Len(@message)-1)
			
			Exec PostLogEntry 'Error', @message, 'UpdateUsersFromWarehouse'
			
			DELETE FROM @tblUserProblems
		End

		----------------------------------------------------------
		-- Look for users for which U_PRN does not match U_netID
		----------------------------------------------------------
		--
		INSERT INTO @tblUserProblems (ID, Warning)
		SELECT ID,
		       'Mismatch between U_PRN and U_netID'
		FROM T_Users
		WHERE U_update = 'y' AND
		      U_PRN <> U_netid AND
		      IsNull(U_netid, '') <> ''
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
			
	
		If @infoOnly = 0 And @myRowCount > 0
		Begin
			Set @message = dbo.CheckPlural(@myRowCount, 'User', 'Users') + ' with mismatch between U_PRN and U_netID: '
			
			SELECT @message = @message + IsNull(U.U_PRN, '??? Undefined U_PRN for ID=' + Convert(varchar(12), U.ID) + ' ???') + ', '
			FROM T_Users U
				    INNER JOIN @tblUserProblems M
				    ON U.ID = M.ID
			ORDER BY U.ID
			
			-- Remove the trailing comma
			Set @message = RTrim(@message)
			Set @message = Left(@message, Len(@message)-1)
			
			Exec PostLogEntry 'Error', @message, 'UpdateUsersFromWarehouse'
			
			DELETE FROM @tblUserProblems
		End


		If @infoOnly <> 0 And Exists (SELECT * from @tblUserProblems)
		Begin		
				SELECT M.Warning,
				       U.ID,
				       IsNull(U.U_HID, '??? Undefined U_HID for ID=' + Convert(varchar(12), U.ID) + ' ???') AS U_HID,
				       U_Name,
				       U_PRN,
				       U_Status,
				       U_email,
				       U_domain,
				       U_netid,
				       U_active,
				       U_created
				FROM T_Users U
				     INNER JOIN @tblUserProblems M
				       ON U.ID = M.ID
				ORDER BY U.ID
		End
		
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUsersFromWarehouse] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUsersFromWarehouse] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUsersFromWarehouse] TO [PNL\D3M580] AS [dbo]
GO
