/****** Object:  StoredProcedure [dbo].[add_update_manager] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_manager]
/****************************************************
**
**  Desc:
**  Updates existing manager values in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   08/22/2007
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @mID varchar(32) = '',
    @mName varchar(50) = '',
    @mControlFromWebsite varchar(32),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    declare @msg varchar(256)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    -- future

    ---------------------------------------------------
    -- Update the T_Mgrs table
    ---------------------------------------------------

    UPDATE T_Mgrs
    SET M_Name = @mName,
        M_ControlFromWebsite = @mControlFromWebsite
    WHERE (M_ID = @mID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0 or @myRowCount <> 1
    begin
        set @msg = 'Error updating T_Mgrs.'
        RAISERROR (@msg, 10, 1)
        return 51000
    end

    ---------------------------------------------------
    --
    ---------------------------------------------------

    return 0

GO
GRANT EXECUTE ON [dbo].[add_update_manager] TO [Mgr_Config_Admin] AS [dbo]
GO
