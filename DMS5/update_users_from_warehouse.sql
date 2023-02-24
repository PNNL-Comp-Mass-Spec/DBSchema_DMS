/****** Object:  StoredProcedure [dbo].[update_users_from_warehouse] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_users_from_warehouse]
/****************************************************
**
**  Desc:   Updates user information in T_Users using linked server SQLSRVPROD02
**
**          Define the linked server using:
**            EXEC sp_addlinkedserver 'SQLSRVPROD02', '', 'SQLNCLI', 'SQLSRVPROD02,915'
**            EXEC sp_addlinkedsrvlogin 'SQLSRVPROD02', 'FALSE', NULL, 'PRISM', '######'
**          PasswordUpdateTool.exe /decode 4HhhXbvo
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/25/2013 mem - Initial version
**          06/07/2013 mem - Removed U_NetID since U_Prn tracks the username
**                         - Added column U_Payroll to track the Payroll number
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/14/2016 mem - Add check for duplicate names
**          08/22/2018 mem - Tabs to spaces
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    BEGIN TRY

        ----------------------------------------------------------
        -- Create a temporary table to track the user information
        -- stored in the data warehouse
        ----------------------------------------------------------
        --
        CREATE TABLE #Tmp_UserInfo (
            ID int not null,                    -- User ID
            U_Name varchar(128) NULL,           -- Last Name, First Name
            Email varchar(128) NULL,            -- E-mail
            Domain varchar(64) NULL,            -- PNL
            NetworkLogin varchar(64) NULL,      -- Username on the domain
            PNNL_Payroll varchar(32) NULL,      -- Payroll number
            Active varchar(8) NOT NULL,         -- Y if an active login; N if a former staff member
            UpdateRequired tinyint NOT NULL     -- Initially 0; this procedure will set this to 1 for staff that need to be updated
        )

        CREATE CLUSTERED INDEX IX_Tmp_UserInfo_ID ON #Tmp_UserInfo (ID)

        ----------------------------------------------------------
        -- Obtain info for staff
        ----------------------------------------------------------
        --
        INSERT INTO #Tmp_UserInfo( ID,
                                   U_Name,
                                   Email,
                                   Domain,
                                   NetworkLogin,
                                   PNNL_Payroll,
                                   Active,
                                   UpdateRequired )
        SELECT U.ID,
               PREFERRED_NAME_FM,
               INTERNET_EMAIL_ADDRESS,
               NETWORK_DOMAIN,
               NETWORK_ID,
               PNNL_PAY_NO,
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
                                   U_Name,
                                   Email,
                                   Domain,
                                   NetworkLogin,
                                   PNNL_Payroll,
                                   Active,
                                   UpdateRequired )
        SELECT U.ID,
               Src.last_name + ', ' + Src.pref_first_name,
               Src.internet_address,
               NetworkInfo.NETWORK_DOMAIN,
               NetworkInfo.NETWORK_ID,
               NULL AS PNNL_Payroll,
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
        -- Look for users that need to be updated
        ----------------------------------------------------------
        --
        UPDATE #Tmp_UserInfo
        SET UpdateRequired = 1
        FROM T_Users U
             INNER JOIN #Tmp_UserInfo Src
               ON U.ID = Src.ID
        WHERE IsNull(U.U_Name, '') <> IsNull(Src.U_Name, IsNull(U.U_Name, '')) OR
              IsNull(U.U_email, '') <> IsNull(Src.Email, IsNull(U.U_email, '')) OR
              IsNull(U.U_domain, '') <> IsNull(Src.Domain, IsNull(U.U_domain, '')) OR
              IsNull(U.U_Payroll, '') <> IsNull(Src.PNNL_Payroll, IsNull(U.U_Payroll, '')) OR
              IsNull(U.U_active, '') <> IsNull(Src.Active, IsNull(U.U_active, ''))
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        ----------------------------------------------------------
        -- Look for updates that would result in a name conflict
        ----------------------------------------------------------
        --
        CREATE TABLE #Tmp_NamesAfterUpdate (
            ID int not null,
            OldName varchar(128) NULL,
            NewName varchar(128) NULL,
            Conflict tinyint not null Default 0
        )

        CREATE CLUSTERED INDEX IX_Tmp_NamesAfterUpdate_ID ON #Tmp_NamesAfterUpdate (ID)
        CREATE INDEX IX_Tmp_NamesAfterUpdate_Name ON #Tmp_NamesAfterUpdate (NewName)

        -- Store the names of the users that will be updated
        --
        INSERT INTO #Tmp_NamesAfterUpdate (ID, OldName, NewName)
        SELECT U.ID, U.U_Name, IsNull(Src.U_Name, U.U_Name) AS NewName
        FROM T_Users U
                INNER JOIN #Tmp_UserInfo Src
                ON U.ID = Src.ID
        WHERE Src.UpdateRequired = 1
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Append the remaining users
        --
        INSERT INTO #Tmp_NamesAfterUpdate (ID, OldName, NewName)
        SELECT ID, U_Name, U_Name
        FROM T_Users
        WHERE NOT ID IN (SELECT ID FROM #Tmp_NamesAfterUpdate)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Look for conflicts
        --
        UPDATE #Tmp_NamesAfterUpdate
        SET Conflict = 1
        WHERE NewName IN ( SELECT NewName
                           FROM #Tmp_NamesAfterUpdate
                           GROUP BY NewName
                           HAVING COUNT(*) > 1 )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Select @myRowCount = COUNT(*)
        FROM #Tmp_NamesAfterUpdate
        WHERE Conflict = 1

        If @myRowCount > 0
        Begin

            Set @message ='User update would result in ' + dbo.check_plural(@myRowCount, 'a duplicate name: ', 'duplicate names: ')

            SELECT @message = @message + IsNull(OldName, '??? Undefined ???')  + ' --> ' + IsNull(NewName, '??? Undefined ???') + ', '
            FROM #Tmp_NamesAfterUpdate
            WHERE Conflict = 1
            ORDER BY NewName, OldName

            -- Remove the trailing comma
            Set @message = RTrim(@message)
            Set @message = Left(@message, Len(@message)-1)

            If @infoOnly = 0
                Exec post_log_entry 'Error', @message, 'update_users_from_warehouse'
            Else
                SELECT @message as Warning

        End

        If @infoOnly = 0
        Begin
            BEGIN TRANSACTION

                ----------------------------------------------------------
                -- Perform the update, skip entries with a potential name conflict
                ----------------------------------------------------------
                --
                UPDATE T_Users
                SET U_Name = CASE WHEN ISNULL(NameConflicts.Conflict, 0) = 1
                                  THEN U.U_Name
                                  ELSE IsNull(Src.U_Name, U.U_Name) End,
                    U_email = IsNull(Src.Email, U.U_email),
                    U_domain = IsNull(Src.Domain, U.U_domain),
                    U_Payroll = IsNull(Src.PNNL_Payroll, U.U_Payroll),
                    U_active = Src.Active,
                    Last_Affected = GetDate()
                FROM T_Users U
                     INNER JOIN #Tmp_UserInfo Src
                       ON U.ID = Src.ID
                     LEFT OUTER JOIN #Tmp_NamesAfterUpdate NameConflicts
                       ON U.ID = NameConflicts.ID
                WHERE UpdateRequired = 1
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                Begin
                    Set @message = 'Updated ' + Convert(varchar(12), @myRowCount) + ' ' + dbo.check_plural(@myRowCount, 'user', 'users') + ' using the PNNL Data Warehouse'
                    print @message

                    Exec post_log_entry 'Normal', @message, 'update_users_from_warehouse'
                End

            COMMIT TRANSACTION

        End
        Else
        Begin
            ----------------------------------------------------------
            -- Preview the updates
            ----------------------------------------------------------
            --
            SELECT U.U_Name,    Src.U_Name AS Name_New,
                   U.U_email,   Src.Email AS EMail_New,
                   U.U_domain,  Src.Domain AS Domain_New,
                   U.U_Payroll, Src.PNNL_Payroll AS Payroll_New,
                   U.U_PRN,     Src.NetworkLogin AS NetworkLogin_New,
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
                                         Warning varchar(128),
                                         NetworkLogin varchar(32) NULL )

        INSERT INTO @tblUserProblems (ID, Warning, NetworkLogin)
        SELECT U.ID,
               'User not found in the Data Warehouse',
               U.U_PRN        -- U_PRN contains the network login
        FROM T_Users U
             LEFT OUTER JOIN #Tmp_UserInfo Src
               ON U.ID = Src.ID
        WHERE U.U_update = 'Y' AND
              Src.ID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        If @infoOnly = 0 And @myRowCount > 0
        Begin
            Set @message = dbo.check_plural(@myRowCount, 'User', 'Users') + ' not found in the Data Warehouse: '

            SELECT @message = @message + IsNull(U.U_HID, '??? Undefined U_HID for ID=' + Convert(varchar(12), U.ID) + ' ???') + ', '
            FROM T_Users U
                    INNER JOIN @tblUserProblems M
                    ON U.ID = M.ID
            ORDER BY U.ID

            -- Remove the trailing comma
            Set @message = RTrim(@message)
            Set @message = Left(@message, Len(@message)-1)

            Exec post_log_entry 'Error', @message, 'update_users_from_warehouse'

            DELETE FROM @tblUserProblems
        End

        ----------------------------------------------------------
        -- Look for users for which U_PRN does not match NetworkLogin
        ----------------------------------------------------------
        --
        INSERT INTO @tblUserProblems (ID, Warning, NetworkLogin)
        SELECT U.ID,
               'Mismatch between U_PRN in DMS and NetworkLogin in Warehouse',
               Src.NetworkLogin
        FROM T_Users U INNER JOIN #Tmp_UserInfo Src
               ON U.ID = Src.ID
        WHERE U.U_update = 'y' AND
              U.U_PRN <> Src.NetworkLogin AND
              IsNull(Src.NetworkLogin, '') <> ''
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount


        If @infoOnly = 0 And @myRowCount > 0
        Begin
            Set @message = dbo.check_plural(@myRowCount, 'User', 'Users') + ' with mismatch between U_PRN in DMS and NetworkLogin in Warehouse: '

            SELECT @message = @message + IsNull(U.U_PRN, '??? Undefined U_PRN for ID=' + Convert(varchar(12), U.ID) + ' ???') +
                              '<>' + IsNull(M.NetworkLogin, '??') + ', '
            FROM T_Users U
                 INNER JOIN @tblUserProblems M
                   ON U.ID = M.ID
            ORDER BY U.ID

            -- Remove the trailing comma
            Set @message = RTrim(@message)
            Set @message = Left(@message, Len(@message)-1)

            Exec post_log_entry 'Error', @message, 'update_users_from_warehouse'

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
                       M.NetworkLogin,
                       U_active,
                       U_created
                FROM T_Users U
                     INNER JOIN @tblUserProblems M
                       ON U.ID = M.ID
                ORDER BY U.ID
        End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        Declare @msg varchar(512) = ERROR_MESSAGE()

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @msg, 'update_users_from_warehouse'

    END CATCH

Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_users_from_warehouse] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_users_from_warehouse] TO [Limited_Table_Write] AS [dbo]
GO
