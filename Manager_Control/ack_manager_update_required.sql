/****** Object:  StoredProcedure [dbo].[ack_manager_update_required] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ack_manager_update_required]
/****************************************************
**
**  Desc:
**      Acknowledges that a manager has seen that
**      ManagerUpdateRequired is True in the manager control DB
**
**      This SP will thus set ManagerUpdateRequired to False for this manager
**
**  Auth:   mem
**  Date:   01/16/2009 mem - Initial version
**          09/09/2009 mem - Added support for 'ManagerUpdateRequired' already being False
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @managerName varchar(128),
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    Declare @mgrID int
    Declare @ParamID int

    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    SELECT @mgrID = M_ID
    FROM T_Mgrs
    WHERE (M_Name = @managerName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount <> 1
    begin
        set @myError = 52002
        set @message = 'Could not find entry for manager: ' + @managername
        goto Done
    end

    ---------------------------------------------------
    -- Update the 'ManagerUpdateRequired' entry for this manager
    ---------------------------------------------------

    UPDATE T_ParamValue
    SET Value = 'False'
    FROM T_ParamType
         INNER JOIN T_ParamValue
           ON T_ParamType.ParamID = T_ParamValue.TypeID
    WHERE (T_ParamType.ParamName = 'ManagerUpdateRequired') AND
          (T_ParamValue.MgrID = @mgrID) AND
          Value <> 'False'
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
        Set @message = 'Acknowledged that update is required'
    Else
    Begin
        -- No rows were updated; may need to make a new entry for 'ManagerUpdateRequired' in the T_ParamValue table
        Set @ParamID = 0

        SELECT @ParamID = ParamID
        FROM T_ParamType
        WHERE (ParamName = 'ManagerUpdateRequired')
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @ParamID > 0
        Begin
            If Exists (SELECT * FROM T_ParamValue WHERE MgrID = @mgrID AND TypeID = @ParamID)
                Set @message = 'ManagerUpdateRequired was already acknowledged in T_ParamValue'
            Else
            Begin
                INSERT INTO T_ParamValue (MgrID, TypeID, Value)
                VALUES (@mgrID, @ParamID, 'False')

                Set @message = 'Acknowledged that update is required (added new entry to T_ParamValue)'
            End
        End
    End

    ---------------------------------------------------
    -- Exit the procedure
    ---------------------------------------------------
Done:
    return @myError

GO
GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [svc-dms] AS [dbo]
GO
