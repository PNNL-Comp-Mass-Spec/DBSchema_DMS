/****** Object:  StoredProcedure [dbo].[update_single_mgr_type_control_param] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_single_mgr_type_control_param]
/****************************************************
**
**  Desc:
**  Changes single manager params for set of given manager Types
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   jds
**  Date:   07/17/2007
**          07/31/2007 grk - changed for 'controlfromwebsite' no longer a parameter
**          03/30/2009 mem - Added optional parameter @callingUser; if provided, then will call alter_entered_by_user_multi_id and possibly alter_event_log_entry_user_multi_id
**          04/16/2009 mem - Now calling update_single_mgr_param_work to perform the updates
**          02/15/2020 mem - Rename the first parameter to @paramName
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramName varchar(32),         -- The parameter name
    @newValue varchar(128),             -- The new value to assign for this parameter
    @managerTypeIDList varchar(2048),
    @callingUser varchar(128) = ''
)
AS
    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ---------------------------------------------------
    -- Create a temporary table that will hold the Entry_ID
    -- values that need to be updated in T_ParamValue
    ---------------------------------------------------
    CREATE TABLE #TmpParamValueEntriesToUpdate (
        EntryID int NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_TmpParamValueEntriesToUpdate ON #TmpParamValueEntriesToUpdate (EntryID)


    ---------------------------------------------------
    -- Find the @paramName entries for the Manager Types in @managerTypeIDList
    ---------------------------------------------------
    --
    INSERT INTO #TmpParamValueEntriesToUpdate (EntryID)
    SELECT T_ParamValue.Entry_ID
    FROM T_ParamValue
         INNER JOIN T_ParamType
           ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
         INNER JOIN T_Mgrs
           ON MgrID = M_ID
    WHERE ParamName = @paramName AND
          M_TypeID IN ( SELECT Item
                        FROM make_table_from_list ( @managerTypeIDList )
                      ) AND
          MgrID IN ( SELECT M_ID
                     FROM T_Mgrs
                     WHERE M_ControlFromWebsite > 0
                     )
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        RAISERROR ('Error finding Manager params to update', 10, 1)
        return 51309
    end

    ---------------------------------------------------
    -- Call update_single_mgr_param_work to perform the update, then call
    -- alter_entered_by_user_multi_id and alter_event_log_entry_user_multi_id for @callingUser
    ---------------------------------------------------
    --
    exec @myError = update_single_mgr_param_work @paramName, @newValue, @callingUser

    return @myError

GO
GRANT EXECUTE ON [dbo].[update_single_mgr_type_control_param] TO [Mgr_Config_Admin] AS [dbo]
GO
