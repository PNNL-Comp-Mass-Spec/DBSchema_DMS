/****** Object:  StoredProcedure [dbo].[PauseManagerTaskRequests] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[PauseManagerTaskRequests] 
/****************************************************
**
**  Desc: 
**      Updates parameter TaskRequestEnableTime for the given manager
**
**      This will stop the analysis manager from requesting new analysis jobs for the length of time specified by @holdoffIntervalMinutes
**
**  Auth:   mem
**  Date:   09/21/2021 mem - Initial version
**
*****************************************************/
(
    @managerName varchar(128),
    @holdoffIntervalMinutes int = 60,
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError Int = 0
    Declare @myRowCount int = 0
    
    Set @managerName = IsNull(@managerName, '')
    Set @holdoffIntervalMinutes = IsNull(@holdoffIntervalMinutes, 60)
    Set @message = ''
    
    Declare @mgrId int    
    Declare @paramId int
    
    ---------------------------------------------------
    -- Confirm that the manager name is valid
    ---------------------------------------------------

    SELECT @mgrId = M_ID
    FROM T_Mgrs
    WHERE M_Name = @managerName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    if @myRowCount <> 1
    begin
        set @myError = 52002
        set @message = 'Could not find entry for manager: ' + @managername
        goto Done
    end

    ---------------------------------------------------
    -- Update the 'TaskRequestEnableTime' entry for this manager
    ---------------------------------------------------

    Declare @newTime varchar(128) = Convert(varchar(128), DateAdd(minute, @holdoffIntervalMinutes, GetDate()), 120)

    UPDATE T_ParamValue
    SET Value = @newTime
    FROM T_ParamType
         INNER JOIN T_ParamValue
           ON T_ParamType.ParamID = T_ParamValue.TypeID
    WHERE T_ParamType.ParamName = 'TaskRequestEnableTime' AND
          T_ParamValue.MgrID = @mgrId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        Set @message = 'Updated TaskRequestEnableTime to ' + @newTime
    End
    Else
    Begin
        -- No rows were updated; may need to make a new entry for 'TaskRequestEnableTime' in the T_ParamValue table
        Set @paramId = 0
        
        SELECT @paramId = ParamID
        FROM T_ParamType
        WHERE ParamName = 'TaskRequestEnableTime'
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        
        If @paramId > 0
        Begin
            If Exists (SELECT * FROM T_ParamValue WHERE MgrID = @mgrId AND TypeID = @paramId)
                Set @message = 'TaskRequestEnableTime is already defined in T_ParamValue; this code should not have been reached'
            Else
            Begin
                INSERT INTO T_ParamValue (MgrID, TypeID, Value)
                VALUES (@mgrId, @paramId, @newTime)
            
                Set @message = 'Updated TaskRequestEnableTime to ' + @newTime + ' (added new entry to T_ParamValue)'
            End
        End
    End
        
    ---------------------------------------------------
    -- Exit the procedure
    ---------------------------------------------------
Done:
    return @myError
    

GO
GRANT EXECUTE ON [dbo].[PauseManagerTaskRequests] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[PauseManagerTaskRequests] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[PauseManagerTaskRequests] TO [svc-dms] AS [dbo]
GO
