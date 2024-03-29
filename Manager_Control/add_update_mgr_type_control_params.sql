/****** Object:  StoredProcedure [dbo].[add_update_mgr_type_control_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_mgr_type_control_params]
/****************************************************
**
**  Desc:
**  Sets all parameters for manager type
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   jds
**  Date:   09/21/2007
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
    @mgrTypeID varchar(32),
    @paramIDList varchar(2048)
AS
    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0
    --
    declare @msg varchar(2000)

    ---------------------------------------------------
    -- Add all parameters in list to manager type that don't already exist
    ---------------------------------------------------

    Insert Into T_MgrType_ParamType_Map(MgrTypeID, ParamTypeID)
    Select @mgrTypeID, *
    from make_table_from_list(@paramIDList)
    where Item NOT IN   (
                    Select ParamTypeID
                    From T_MgrType_ParamType_Map
                    where MgrTypeID = @mgrTypeID
                    )

    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Error trying to add parameters to Manager type ID: ' + @mgrTypeID
        RAISERROR (@msg, 10, 1)
        return 51310
    end

    return @myError

GO
GRANT EXECUTE ON [dbo].[add_update_mgr_type_control_params] TO [Mgr_Config_Admin] AS [dbo]
GO
