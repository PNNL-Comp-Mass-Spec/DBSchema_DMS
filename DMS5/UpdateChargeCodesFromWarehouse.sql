/****** Object:  StoredProcedure [dbo].[UpdateChargeCodesFromWarehouse] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure UpdateChargeCodesFromWarehouse
/****************************************************
**
**	Desc: 
**		Updates charge code (aka work package) information in T_Charge_Code using linked server SQLSRVPROD02
**
**		Defined the linked server using:
**			EXEC sp_addlinkedserver 'SQLSRVPROD02', '', 'SQLNCLI', 'SQLSRVPROD02,915'
**			EXEC sp_addlinkedsrvlogin 'SQLSRVPROD02', 'FALSE', NULL, 'PRISM', '5GigYawn'
**
**	Return values: 0: success, otherwise, error code
**
**	Auth: 	mem
**	Date: 	06/04/2013 mem - Initial version
**			06/05/2013 mem - Now calling AutoAddChargeCodeUsers
**			06/06/2013 mem - Now caching column DEACT_SW, which is "Y" when the charge code is Deactivated (can also be "R"; don't know what that means)
**			12/03/2013 mem - Now changing Charge_Code_State to 0 for Deactivated work packages
**						   - Now populating Activation_State when inserting new rows via the merge
**			08/13/2015 mem - Added field @ExplicitChargeCodeList
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@updateAll tinyint = 0,						-- Set to 1 to force an update of all rows in T_Charge_Code; by default, filters on charge codes based on Setup_Date and Auth_Amt
	@ExplicitChargeCodeList varchar(2000)='',	-- Comma separated list of Charge codes (work packages) to add to T_Charge_Code regardless of filters.  When used, other charge codes are ignored
	@message varchar(512)='' output
)
AS
	Set XACT_ABORT, nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0
	declare @MergeUpdateCount int = 0
	declare @MergeInsertCount int = 0

	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	----------------------------------------------------------
	-- Validate the inputs
	----------------------------------------------------------
	
	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @updateAll = IsNull(@updateAll, 0)
	Set @ExplicitChargeCodeList = IsNull(@ExplicitChargeCodeList, '')
	Set @message = ''
	
	---------------------------------------------------
	-- Create the temporary table that will be used to
	-- track the number of inserts, updates, and deletes 
	-- performed by the MERGE statement
	---------------------------------------------------
	
	CREATE TABLE #Tmp_UpdateSummary (
		UpdateAction varchar(32)
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)


	-- Create a temporary table to keep track of WPs used within the last 12 months
	CREATE TABLE #Tmp_WPsInUseLast3Years (
		Charge_Code varchar(64),
		Most_Recent_Usage datetime
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_WPsInUseLast3Years ON #Tmp_WPsInUseLast3Years (Charge_Code)

	-- Create a temporary table to keep track of WPs in @ExplicitChargeCodeList
	CREATE TABLE #Tmp_WPsExplicit (
		Charge_Code varchar(64)
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_WPsExplicit ON #Tmp_WPsExplicit (Charge_Code)
	
	BEGIN TRY 

		If @ExplicitChargeCodeList <> ''
		Begin
			-- Populate #IX_Tmp_WPsExplicit
			INSERT INTO #Tmp_WPsExplicit (Charge_Code)
			SELECT Value
			FROM dbo.udfParseDelimitedList(@ExplicitChargeCodeList, ',')			
		End

		
		----------------------------------------------------------
		-- Create a temporary table to track the charge code information
		-- stored in the data warehouse
		----------------------------------------------------------
		--
		CREATE TABLE #Tmp_ChargeCode(
			Charge_Code varchar(6) NOT NULL,
			Resp_PRN varchar(5) NULL,
			Resp_HID varchar(7) NULL,
			WBS_Title varchar(60) NULL,
			Charge_Code_Title varchar(30) NULL,
			SubAccount varchar(8) NULL,
			SubAccount_Title varchar(60) NULL,
			Setup_Date datetime NOT NULL,
			SubAccount_Effective_Date datetime NULL,
			Inactive_Date datetime NULL,
			SubAccount_Inactive_Date datetime NULL,
			Deactivated varchar(1) NOT NULL,
			Auth_Amt numeric(12, 0) NOT NULL,
			Auth_PRN varchar(5) NULL,
			Auth_HID varchar(7) NULL			
		)
		
		CREATE CLUSTERED INDEX IX_Tmp_ChargeCode ON #Tmp_ChargeCode (Charge_Code)

		----------------------------------------------------------
		-- Obtain charge code info
		----------------------------------------------------------
		--
		Set @CurrentLocation = 'Query opwhse'

		If Exists (Select * from #Tmp_WPsExplicit)
		Begin
			INSERT INTO #Tmp_ChargeCode( Charge_Code,
			                             Resp_PRN,
			                             Resp_HID,
			                             WBS_Title,
			                             Charge_Code_Title,
			                             SubAccount,
			                             SubAccount_Title,
			                             Setup_Date,
			                             SubAccount_Effective_Date,
			                             Inactive_Date,
			                             SubAccount_Inactive_Date,
			                             Deactivated,
			                             Auth_Amt,
			                             Auth_PRN,
			                             Auth_HID )
			SELECT CC.CHARGE_CD,
			       CC.RESP_PAY_NO,
			       CC.RESP_HID,
			       CT.WBS_TITLE,
			       CC.CHARGE_CD_TITLE,
			       CC.SUBACCT,
			       CT.SA_TITLE,
			       CC.SETUP_DATE,
			       CC.SUBACCT_EFF_DATE,
			       CC.INACT_DATE,
			       CC.SUBACCT_INACT_DATE,
			       CC.DEACT_SW,
			       CC.AUTH_AMT,
			       CC.AUTH_PAY_NO,
			       CC.AUTH_HID
			FROM SQLSRVPROD02.opwhse.dbo.VW_PUB_CHARGE_CODE CC
			     INNER JOIN #Tmp_WPsExplicit
			       ON CC.CHARGE_CD = #Tmp_WPsExplicit.Charge_Code
			     LEFT OUTER JOIN SQLSRVPROD02.opwhse.dbo.VW_PUB_CHARGE_CODE_TRAIL CT
			       ON CC.CHARGE_CD = CT.CHARGE_CD

		End
		Else
		Begin
			
			INSERT INTO #Tmp_ChargeCode( Charge_Code,
			                             Resp_PRN,
			                             Resp_HID,
			                             WBS_Title,
			                             Charge_Code_Title,
			                             SubAccount,
			                             SubAccount_Title,
			                             Setup_Date,
			                             SubAccount_Effective_Date,
			                             Inactive_Date,
			                             SubAccount_Inactive_Date,
			                             Deactivated,
			                             Auth_Amt,
			                             Auth_PRN,
			                             Auth_HID )
			SELECT CC.CHARGE_CD,
			       CC.RESP_PAY_NO,
			       CC.RESP_HID,
			       CT.WBS_TITLE,
			       CC.CHARGE_CD_TITLE,
			       CC.SUBACCT,
			       CT.SA_TITLE,
			       CC.SETUP_DATE,
			       CC.SUBACCT_EFF_DATE,
			       CC.INACT_DATE,
			       CC.SUBACCT_INACT_DATE,
			       CC.DEACT_SW,
			       CC.AUTH_AMT,
			       CC.AUTH_PAY_NO,
			       CC.AUTH_HID
			FROM SQLSRVPROD02.opwhse.dbo.VW_PUB_CHARGE_CODE CC
			     LEFT OUTER JOIN SQLSRVPROD02.opwhse.dbo.VW_PUB_CHARGE_CODE_TRAIL CT
			       ON CC.CHARGE_CD = CT.CHARGE_CD
			WHERE	(CC.SETUP_DATE >= DateAdd(year, -10, GetDate()) AND			-- Filter out charge codes created over 10 years ago
					 CC.AUTH_AMT > 0 AND											-- Ignore charge codes with an authorization amount of $0
					 CC.CHARGE_CD NOT LIKE 'RB%' AND								-- Filter out charge codes that are used for purchasing, not labor
					 CC.CHARGE_CD NOT LIKE '[RV]%'
					)
					OR
					(CC.SETUP_DATE >= DateAdd(year, -2, GetDate()) AND			-- Filter out charge codes created over 2 years ago
					 CC.RESP_HID IN (												-- Filter on charge codes where the Responsible person is an active DMS user; this includes codes with Auth_Amt = 0
						SELECT SUBSTRING(U_HID, 2, 20)
						FROM T_Users 
						WHERE U_Status = 'Active' AND LEN(U_HID) > 1
						) AND
					 CC.CHARGE_CD NOT LIKE 'RB%' AND								-- Filter out charge codes that are used for purchasing, not labor
					 CC.CHARGE_CD NOT LIKE '[RV]%'
					)
					OR
					(@updateAll > 0 AND CC.CHARGE_CD IN (SELECT Charge_Code FROM T_Charge_Code))
				
		End		  
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		

		If @infoOnly = 0
		Begin
		
			----------------------------------------------------------
			-- Merge new/updated charge codes
			--
			-- Note that field Activation_State will be auto-updated by trigger trig_u_Charge_Code
			-- whenever values in any of these fields change:
			--    Deactivated, Charge_Code_State, Usage_SamplePrep, Usage_RequestedRun, Activation_State
	   
			----------------------------------------------------------
			--
			Set @CurrentLocation = 'Merge data'

			MERGE T_Charge_Code AS Target
			USING 
				( SELECT Charge_Code, Resp_PRN, Resp_HID, WBS_Title, Charge_Code_Title,
			             SubAccount, SubAccount_Title, Setup_Date, SubAccount_Effective_Date,
			             Inactive_Date, SubAccount_Inactive_Date, Deactivated, Auth_Amt, Auth_PRN, Auth_HID
				  FROM #Tmp_ChargeCode
				) AS Source ( Charge_Code, Resp_PRN, Resp_HID, WBS_Title, Charge_Code_Title,
			                  SubAccount, SubAccount_Title, Setup_Date, SubAccount_Effective_Date,
			                  Inactive_Date, SubAccount_Inactive_Date, Deactivated, Auth_Amt, Auth_PRN, Auth_HID )
			ON ( target.Charge_Code = source.Charge_Code )
			WHEN Matched  AND 
					(	IsNull(target.Resp_PRN, '') <> IsNull(source.Resp_PRN, '') OR
						IsNull(target.Resp_HID, '') <> IsNull(source.Resp_HID, '') OR
						IsNull(target.WBS_Title, '') <> IsNull(source.WBS_Title, '') OR
						IsNull(target.Charge_Code_Title, '') <> IsNull(source.Charge_Code_Title, '') OR
						IsNull(target.SubAccount, '') <> IsNull(source.SubAccount, '') OR
						IsNull(target.SubAccount_Title, '') <> IsNull(source.SubAccount_Title, '') OR
						target.Setup_Date <> source.Setup_Date OR
						IsNull(target.SubAccount_Effective_Date, '') <> IsNull(source.SubAccount_Effective_Date, '') OR
						IsNull(target.Inactive_Date, '') <> IsNull(source.Inactive_Date, '') OR
						IsNull(target.SubAccount_Inactive_Date, '') <> IsNull(source.SubAccount_Inactive_Date, '') OR
						target.Deactivated <> source.Deactivated OR
						target.Auth_Amt <> source.Auth_Amt OR
						IsNull(target.Auth_PRN, '') <> IsNull(source.Auth_PRN, '') OR
						IsNull(target.Auth_HID, '') <> IsNull(source.Auth_HID, '')						
						)
				THEN UPDATE SET
					Resp_PRN = source.Resp_PRN,
					Resp_HID = source.Resp_HID,
					WBS_Title = source.WBS_Title,
					Charge_Code_Title = source.Charge_Code_Title,
					SubAccount = source.SubAccount,
					SubAccount_Title = source.SubAccount_Title,
					Setup_Date = source.Setup_Date,
					SubAccount_Effective_Date = source.SubAccount_Effective_Date,
					Inactive_Date = source.Inactive_Date,
					SubAccount_Inactive_Date = source.SubAccount_Inactive_Date,
					Deactivated = source.Deactivated,
					Auth_Amt = source.Auth_Amt,
					Auth_PRN = source.Auth_PRN,
					Auth_HID = source.Auth_HID,
					Last_Affected = GetDate()
			WHEN NOT Matched BY Target 
				THEN INSERT  (
			             Charge_Code, Resp_PRN, Resp_HID, WBS_Title, Charge_Code_Title,
			             SubAccount, SubAccount_Title, Setup_Date, SubAccount_Effective_Date,
			             Inactive_Date, SubAccount_Inactive_Date, Deactivated, Auth_Amt, Auth_PRN, Auth_HID,
			             Auto_Defined, Charge_Code_State, Activation_State, Last_Affected
					) VALUES
					( source.Charge_Code, source.Resp_PRN, source.Resp_HID, source.WBS_Title, source.Charge_Code_Title,
			          source.SubAccount, source.SubAccount_Title, source.Setup_Date, source.SubAccount_Effective_Date,
			          source.Inactive_Date, source.SubAccount_Inactive_Date, source.Deactivated, source.Auth_Amt, source.Auth_PRN, source.Auth_HID,
			          1,		-- Auto_Defined=1
			  1,		-- Charge_Code_State = 1 (Interest Unknown)
			   dbo.ChargeCodeActivationState(source.Deactivated, 1, 0, 0),
			          GetDate() 
					)
			OUTPUT $ACTION INTO #Tmp_UpdateSummary ;

			set @MergeUpdateCount = 0
			set @MergeInsertCount = 0

			SELECT @MergeInsertCount = COUNT(*)
			FROM #Tmp_UpdateSummary
			WHERE UpdateAction = 'INSERT'

			SELECT @MergeUpdateCount = COUNT(*)
			FROM #Tmp_UpdateSummary
			WHERE UpdateAction = 'UPDATE'
			
			If @MergeUpdateCount > 0 OR @MergeInsertCount > 0
			Begin
				Set @message = 'Updated T_Charge_Code: ' + Convert(varchar(12), @MergeInsertCount) + ' added; ' + Convert(varchar(12), @MergeUpdateCount) + ' updated'
				
				Exec PostLogEntry 'Normal', @message, 'UpdateChargeCodesFromWarehouse'
				Set @message = ''
			End
			
			----------------------------------------------------------
			-- Update usage columns
			----------------------------------------------------------
			--
			Set @CurrentLocation = 'Update usage columns'
			
			exec UpdateChargeCodeUsage @infoonly=0
			
			----------------------------------------------------------
			-- Update Inactive_Date_Most_Recent
			-- based on Inactive_Date and SubAccount_Inactive_Date
			----------------------------------------------------------
			--
			Set @CurrentLocation = 'Update Inactive_Date_Most_Recent using Inactive_Date and SubAccount_Inactive_Date'
			
			UPDATE T_Charge_Code
			SET Inactive_Date_Most_Recent = OuterQ.Inactive_Date_Most_Recent
			FROM T_Charge_Code target
			     INNER JOIN ( SELECT Charge_Code,
			                         Inactive1,
			                         Inactive2,
			                         CASE
			                             WHEN Inactive1 >= IsNull(Inactive2, Inactive1) THEN Inactive1
			                             ELSE Inactive2
			                         END AS Inactive_Date_Most_Recent
			                  FROM ( SELECT Charge_Code,
			                                COALESCE(Inactive_Date, SubAccount_Inactive_Date, Inactive_Date_Most_Recent) AS Inactive1,
			                                COALESCE(SubAccount_Inactive_Date, Inactive_Date, Inactive_Date_Most_Recent) AS Inactive2
			                 FROM T_Charge_Code 
			                        ) InnerQ 
			              ) OuterQ
			       ON target.Charge_Code = OuterQ.Charge_Code AND
			          NOT OuterQ.Inactive_Date_Most_Recent IS NULL
			WHERE target.Inactive_Date_Most_Recent <> OuterQ.Inactive_Date_Most_Recent OR
			    target.Inactive_Date_Most_Recent IS NULL
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			----------------------------------------------------------
			-- Update Inactive_Date_Most_Recent
			-- based on Deactivated
			----------------------------------------------------------
			--
			Set @CurrentLocation = 'Update Inactive_Date_Most_Recent using Deactivated'
			
			UPDATE T_Charge_Code
			SET Inactive_Date_Most_Recent = GetDate()
			WHERE (Deactivated = 'Y') AND (Inactive_Date_Most_Recent IS NULL)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount      


			-- Set the state to 0 for deactivated work packages
			--
			UPDATE T_Charge_Code
			SET Charge_Code_State = 0
			WHERE (Charge_Code_State <> 0) AND
			       Deactivated = 'Y'
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount      
			       
			       
			-- Look for work packages that have a state of 0 but were created within the last 2 years and are not deactivated
			-- Change their state back to 1 (Interest Unknown)
			--
			UPDATE T_Charge_Code
			SET Charge_Code_State = 1
			WHERE (Charge_Code_State = 0) AND
			       Deactivated = 'N' AND
			       Setup_Date > DATEADD(year, -2, GETDATE())
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount      
			
            ----------------------------------------------------------
			-- Auto-mark active charge codes that are currently in state 1 = "Interest Unknown"
			-- Change the state to 2 for any that have sample prep requests or requested runs that use the charge code
			----------------------------------------------------------
			--
			Set @CurrentLocation = 'Update Charge_Code_State'
			
			UPDATE T_Charge_Code
			SET Charge_Code_State = 2
			WHERE (Charge_Code_State = 1) AND
			      (Usage_SamplePrep > 0 OR
			       Usage_RequestedRun > 0)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			----------------------------------------------------------
			-- Find WPs used within the last 3 years
			----------------------------------------------------------
			--
            INSERT INTO #Tmp_WPsInUseLast3Years ( Charge_Code, Most_Recent_Usage)
            SELECT Charge_Code, Max(Most_Recent_Usage)
            FROM ( SELECT A.Charge_Code,
                          CASE WHEN A.Most_Recent_SPR >= IsNUll(B.Most_Recent_RR, A.Most_Recent_SPR) 
                               THEN A.Most_Recent_SPR
                               ELSE B.Most_Recent_RR
                          END AS Most_Recent_Usage
                   FROM ( SELECT CC.Charge_Code,
                                 MAX(SPR.Created) AS Most_Recent_SPR
                          FROM T_Charge_Code CC
                               INNER JOIN T_Sample_Prep_Request SPR
                                 ON CC.Charge_Code = SPR.Work_Package_Number
                          GROUP BY CC.Charge_Code 
                  ) A INNER JOIN
             ( SELECT CC.Charge_Code, 
                                 MAX(RR.RDS_created) AS Most_Recent_RR
                          FROM T_Requested_Run RR
                               INNER JOIN T_Charge_Code CC
                                 ON RR.RDS_WorkPackage = CC.Charge_Code
                          GROUP BY CC.Charge_Code 
                        ) B
                          ON A.Charge_Code = B.Charge_Code 
                  ) UsageQ
            WHERE Most_Recent_Usage >= DateAdd(year, -3, GetDate())
            GROUP BY Charge_Code
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount


			----------------------------------------------------------
			-- Auto-mark Inactive charge codes that have usage counts of 0 and became inactive at least 6 months ago
			-- Note that DMS updates Inactive_Date_Most_Recent from Null to a valid date when it finds that a charge_code has been deactivated
			----------------------------------------------------------
			--
			UPDATE T_Charge_Code
			SET Charge_Code_State = 0
			WHERE Charge_Code_State IN (1, 2) AND
			      Inactive_Date_Most_Recent < DATEADD(month, -6, GETDATE()) AND
			      IsNull(Usage_SamplePrep, 0) = 0 AND
			      IsNull(Usage_RequestedRun, 0) = 0
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			----------------------------------------------------------
			-- Auto-mark Inactive charge codes that became inactive at least 12 months ago
			-- and haven't had any recent sample prep request or requested run usage
			----------------------------------------------------------
			--
			UPDATE T_Charge_Code
			SET Charge_Code_State = 0
			WHERE Charge_Code_State IN (1, 2) AND
			      Inactive_Date_Most_Recent < DATEADD(month, -12, GETDATE()) AND
			      Charge_Code NOT IN ( SELECT Charge_Code
			                           FROM #Tmp_WPsInUseLast3Years
			                           WHERE Most_Recent_Usage >= DateAdd(month, -12, GetDate()) )
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount

			----------------------------------------------------------
			-- Auto-mark Inactive charge codes that were created at least 3 years ago
			-- and haven't had any sample prep request or requested run usage within the last 3 years
			-- The goal is to hide charge codes that are still listed as active in the warehouse, yet have not been used in DMS for 3 years
			----------------------------------------------------------
			--
			UPDATE T_Charge_Code
			SET Charge_Code_State = 0
			WHERE Charge_Code_State IN (1, 2) AND
			      Setup_Date < DATEADD(year, -3, GETDATE()) AND
			      Charge_Code NOT IN ( SELECT Charge_Code
			                           FROM #Tmp_WPsInUseLast3Years )
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount


			----------------------------------------------------------
			-- Add new users as DMS_Guest users
			-- We only add users associated with charge codes that have been used in DMS
			----------------------------------------------------------
			--
			exec @myError = AutoAddChargeCodeUsers @infoOnly = 0

		End
		Else
		Begin
			----------------------------------------------------------
			-- Preview the updates
			----------------------------------------------------------
			--
		
			SELECT CASE WHEN T_Charge_Code.Charge_Code IS NULL 
			            THEN 'New CC'
			            ELSE 'Existing CC'
			       END AS State,
			       #Tmp_ChargeCode.*
			FROM #Tmp_ChargeCode
			     LEFT OUTER JOIN T_Charge_Code
			       ON #Tmp_ChargeCode.Charge_Code = T_Charge_Code.Charge_Code
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
		End

	
		
	END TRY
	BEGIN CATCH 
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateChargeCodesFromWarehouse')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output
								
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateChargeCodesFromWarehouse] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateChargeCodesFromWarehouse] TO [PNL\D3M578] AS [dbo]
GO
