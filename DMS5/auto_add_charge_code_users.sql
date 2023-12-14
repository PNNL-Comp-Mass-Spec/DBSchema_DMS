/****** Object:  StoredProcedure [dbo].[auto_add_charge_code_users] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[auto_add_charge_code_users]
/****************************************************
**
**  Desc:   Examines the responsible user for active Charge_Codes with one or more sample prep requests or requested runs
**          Auto-adds any users who are not in T_User
**
**          Uses linked server SQLSRVPROD02
**
**          Define the linked server using:
**            EXEC sp_addlinkedserver 'SQLSRVPROD02', '', 'SQLNCLI', 'SQLSRVPROD02,915'
**            EXEC sp_addlinkedsrvlogin 'SQLSRVPROD02', 'FALSE', NULL, 'PRISM', '5GigYawn'
**
**  Arguments:
**    @infoOnly                     When true, preview updates
**    @includeInactiveChargeCodes   When true, add users for both active and inactive charge codes
**    @message                      Output message
**
**  Auth:   mem
**  Date:   06/05/2013 mem - Initial Version
**          06/10/2013 mem - Now storing payroll number in U_Payroll and Network_ID in U_PRN
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          02/17/2022 mem - Tabs to spaces
**          02/08/2023 bcg - Update view column name
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          05/19/2023 mem - Add missing Else
**          05/24/2023 mem - When previewing new users, show charge codes associated with each new user
**          12/13/2023 mem - Add argument @includeInactiveChargeCodes
**                         - Also look for new users that do not have a payroll number (column CC.Resp_PRN)
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @includeInactiveChargeCodes tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @infoOnly                   = IsNull(@infoOnly, 0)
    Set @includeInactiveChargeCodes = IsNull(@includeInactiveChargeCodes, 0)
    Set @message                    = ''

    ---------------------------------------------------
    -- Create temporary tables to track users to add
    --
    -- Column Resp_PRN in t_charge_code is actually the payroll number (e.g. '3L243') and not username
    -- It is null for staff whose username starts with the first four letters of their last name, as has been the case since 2010
    --
    -- Table Tmp_NewUsers tracks charge codes where Resp_PRN is not null
    -- Table Tmp_NewUsersByHID tracks charge codes where Resp_PRN is null
    ---------------------------------------------------

    CREATE TABLE #Tmp_NewUsers (
        Payroll varchar(12),
        HID varchar(12),
        LastName_FirstName varchar(128),
        Network_ID varchar(12) NULL,
        Charge_Code_First varchar(12) NULL,
        Charge_Code_Last varchar(12) NULL,
        DMS_ID int NULL
    )

    CREATE TABLE #Tmp_NewUsersByHID (
        HID varchar(12),
        LastName_FirstName varchar(128),
        Network_ID varchar(12) NULL,
        Charge_Code_First varchar(12) NULL,
        Charge_Code_Last varchar(12) NULL,
        DMS_ID int NULL
    )

    BEGIN TRY

        ---------------------------------------------------
        -- Look for new users that have a payroll number (column CC.Resp_PRN)
        ---------------------------------------------------

        INSERT INTO #Tmp_NewUsers (Payroll, HID, Charge_Code_First, Charge_Code_Last)
        SELECT CC.Resp_PRN, MAX(CC.Resp_HID), Min(CC.Charge_Code) AS Charge_Code_First, Max(CC.Charge_Code) AS Charge_Code_Last
        FROM T_Charge_Code CC
             LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map UMap
               ON CC.Charge_Code = UMap.Charge_Code
        WHERE NOT CC.Resp_PRN Is Null AND
              NOT CC.Resp_HID Is Null AND
              UMap.Username IS NULL AND
              (CC.Charge_Code_State > 0 OR @includeInactiveChargeCodes > 0) AND
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

        ---------------------------------------------------
        -- Look for new users that do not have a payroll number (column CC.Resp_PRN)
        ---------------------------------------------------

        INSERT INTO #Tmp_NewUsersByHID (HID, Charge_Code_First, Charge_Code_Last)
        SELECT CC.Resp_HID, Min(CC.Charge_Code) AS Charge_Code_First, Max(CC.Charge_Code) AS Charge_Code_Last
        FROM t_charge_code CC
             LEFT OUTER JOIN V_Charge_Code_Owner_DMS_User_Map UMap
               ON CC.charge_code = UMap.charge_code
        WHERE CC.Resp_PRN Is Null AND
              NOT CC.Resp_HID Is Null AND
              UMap.Username IS NULL AND
              (CC.Charge_Code_State > 0 OR @includeInactiveChargeCodes > 0) AND
              (CC.Usage_SamplePrep > 0 OR
               CC.Usage_RequestedRun > 0)
        GROUP BY CC.Resp_HID;

        UPDATE #Tmp_NewUsersByHID
        SET Network_ID = W.NETWORK_ID,
            LastName_FirstName = W.PREFERRED_NAME_FM
        FROM SQLSRVPROD02.opwhse.dbo.VW_PUB_BMI_EMPLOYEE W
        WHERE #Tmp_NewUsersByHID.HID = W.HANFORD_ID AND
              Coalesce(W.NETWORK_ID, '') <> '';

        ---------------------------------------------------
        -- Append users to #Tmp_NewUsers
        ---------------------------------------------------

        INSERT INTO #Tmp_NewUsers (Payroll, HID, Charge_Code_First, Charge_Code_Last, Network_ID, LastName_FirstName)
        SELECT Null AS Payroll,
               Src.HID,
               Src.Charge_Code_First,
               Src.Charge_Code_Last,
               Src.Network_ID,
               Src.LastName_FirstName
        FROM #Tmp_NewUsersByHID Src
             LEFT OUTER JOIN #Tmp_NewUsers NewUsers
               ON Src.HID = NewUsers.HID
        WHERE Coalesce(Src.Network_ID, '') <> '' AND
              NewUsers.HID Is Null;

        If @infoOnly = 0
        Begin
            If Exists (SELECT Network_ID FROM #Tmp_NewUsers WHERE NOT Network_ID Is Null)
            Begin

                INSERT INTO T_Users( U_PRN,         -- Network_ID (aka login) goes in the U_PRN field
                                     U_Name,
                                     U_HID,
                                     U_Payroll,     -- Payroll number goes in the Payroll field
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
                WHERE NOT Network_ID Is Null
                ORDER BY Network_ID
                                --
                SELECT @myError = @@error, @myRowCount = @@rowcount
                --
                if @myError <> 0
                begin
                    set @message = 'Error auto-adding new users'

                    Exec post_log_entry 'Error', @message, 'auto_add_charge_code_users'
                    return 51100
                end

                If @myRowCount > 0
                Begin
                    Set @message = 'Auto added ' + Convert(varchar(12), @myRowCount) + dbo.check_plural(@myRowCount, ' user', ' users') + ' to T_Users since they are associated with charge codes used by DMS'
                    Exec post_log_entry 'Normal', @message, 'auto_add_charge_code_users'
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
                    Exec post_log_entry 'Error', @message, 'auto_add_charge_code_users'
                End
                Else
                Begin
                    INSERT INTO T_User_Operations_Permissions (U_ID, Op_ID)
                    SELECT DMS_ID, @OperationID
                    FROM #Tmp_NewUsers
                         INNER JOIN t_users U
                           ON #Tmp_NewUsers.Network_ID = U.U_PRN;
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
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'auto_add_charge_code_users'
    END CATCH

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[auto_add_charge_code_users] TO [DDL_Viewer] AS [dbo]
GO
