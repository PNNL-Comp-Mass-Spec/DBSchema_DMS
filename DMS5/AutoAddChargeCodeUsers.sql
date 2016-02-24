/****** Object:  StoredProcedure [dbo].[AutoAddChargeCodeUsers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure AutoAddChargeCodeUsers
/****************************************************
**
**	Desc:	Examines the responsible user for active Charge_Codes with one or more sample prep requests or requested runs
**			Auto-adds any users who are not in T_User
**
**			Uses linked server SQLSRVPROD02
**
**		Defined the linked server using:
**			EXEC sp_addlinkedserver 'SQLSRVPROD02', '', 'SQLNCLI', 'SQLSRVPROD02,915'
**			EXEC sp_addlinkedsrvlogin 'SQLSRVPROD02', 'FALSE', NULL, 'PRISM', '5GigYawn'
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	06/05/2013 mem - Initial Version
**			06/10/2013 mem - Now storing payroll number in U_Payroll and Network_ID in U_PRN
**			02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512)='' output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0
     
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------
	
	Set @infoOnly = IsNull(@infoOnly, 0)
	set @message = ''

	---------------------------------------------------
	-- Create temporary table to keep track of users to add
	---------------------------------------------------
	
	CREATE TABLE #Tmp_NewUsers (
		Payroll varchar(12),
		HID varchar(12),	
		LastName_FirstName varchar(128),
		Network_ID varchar(12) NULL,	
		DMS_ID int NULL
	)

	BEGIN TRY 

		INSERT INTO #Tmp_NewUsers (Payroll, HID)
		SELECT CC.Resp_PRN, MAX(CC.Resp_HID)
		FROM T_Charge_Code CC
		     LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map UMap
		       ON CC.Charge_Code = UMap.Charge_Code
		WHERE UMap.U_PRN IS NULL AND
		      CC.Charge_Code_State > 0 AND
		      (CC.Usage_SamplePrep > 0 OR
		       CC.Usage_RequestedRun > 0)
		GROUP BY CC.Resp_PRN
    
    	
		UPDATE #Tmp_NewUsers
		SET Network_ID = W.Network_ID,
			LastName_FirstName = PREFERRED_NAME_FM
		FROM #Tmp_NewUsers Target
			INNER JOIN SQLSRVPROD02.opwhse.dbo.VW_PUB_BMI_EMPLOYEE W
			ON Target.HID = W.HANFORD_ID
		WHERE IsNull(W.Network_ID, '') <> ''

		If @infoOnly = 0
		Begin
			If Exists (SELECT * FROM #Tmp_NewUsers WHERE NOT Network_ID Is Null)
			Begin
		

				INSERT INTO T_Users( U_PRN,         -- Network_ID (aka login) goes in the U_PRN field
									 U_Name,
									 U_HID,
									 U_Payroll,		-- Payroll number goes in the Payroll field
									 U_Status,
									 U_update,
									 U_comment )
				SELECT Network_ID,
					   LastName_FirstName,
					   'H' + HID,
					   Payroll,
					   'Active' AS U_Status,
					   'Y' AS U_update,
					   '' AS U_comment
				FROM #Tmp_NewUsers
				ORDER BY Network_ID
								--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				--
				if @myError <> 0
				begin
					set @message = 'Error auto-adding new users'
					
					Exec PostLogEntry 'Error', @message, 'AutoAddChargeCodeUsers'
					return 51100
				end
				
				If @myRowCount > 0
				Begin
					Set @message = 'Auto added ' + Convert(varchar(12), @myRowCount) + dbo.CheckPlural(@myRowCount, ' user', ' users') + ' to T_Users since they are associated with charge codes used by DMS'
					Exec PostLogEntry 'Normal', @message, 'AutoAddChargeCodeUsers'
				End


				UPDATE #Tmp_NewUsers
				SET DMS_ID = U.ID
				FROM #Tmp_NewUsers
				     INNER JOIN T_Users U
				       ON #Tmp_NewUsers.Network_ID = U.U_PRN


				---------------------------------------------------
				-- Define the DMS_Guest operation for the newly added users
				---------------------------------------------------

				Declare @OperationID int = 0
				
				SELECT @OperationID = ID
				FROM T_User_Operations
				WHERE Operation ='DMS_Guest'
				
				
				If IsNull(@OperationID, 0) = 0
				Begin
					Set @message = 'User operation DMS_Guest not found in T_User_Operations'
					Exec PostLogEntry 'Error', @message, 'AutoAddChargeCodeUsers'
				End
				Begin
					INSERT INTO T_User_Operations_Permissions (U_ID, Op_ID)
					SELECT DMS_ID, @OperationID
					FROM #Tmp_NewUsers
				End
				
			End
		End
		Else
		Begin
			-- Preview the new users
			SELECT *
			FROM #Tmp_NewUsers
			WHERE NOT Network_ID Is Null
			
		End


	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	return 0

GO
