/****** Object:  StoredProcedure [dbo].[add_update_param_type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_param_type]
/****************************************************
**
**  Desc:
**  Updates existing parameter Type values in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   04/01/2008
**          04/27/2009 mem - Added support for @mode = 'add'
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramID varchar(32) = '',
    @paramName varchar(50) = '',
    @paramPicklistName varchar(50),
    @paramComment varchar(255),
    @mode varchar(12) = 'add', -- or 'update'
    @message varchar(512) = '' output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    set @message = ''

    declare @msg varchar(256)
    declare @paramNameCurrent varchar(128)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @mode = IsNull(@mode, '??')
    Set @paramID = IsNull(@paramID, '')
    Set @paramName = IsNull(@paramName, '')

    if @mode <> 'add' and @mode <> 'update'
    Begin
        set @msg = 'Unsupported mode: ' + @mode
        RAISERROR (@msg, 10, 1)
        return 51000
    End

    If @paramName = ''
    Begin
        set @msg = 'Parameter name is empty; unable to continue'
        RAISERROR (@msg, 10, 1)
        return 51001
    End

    If @mode = 'add'
    Begin

        INSERT INTO T_ParamType (ParamName, PicklistName, Comment)
        VALUES (@paramName, @paramPicklistName, @paramComment)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Error adding new parameter to T_ParamType'
            RAISERROR (@msg, 10, 1)
            return 51002
        end
    End


    If @mode = 'update'
    Begin
        ---------------------------------------------------
        -- Update the T_Mgrs table
        ---------------------------------------------------

        SELECT @paramNameCurrent = ParamName
        FROM T_ParamType
        WHERE (ParamID = @paramID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Error looking for ID ' + @paramID + ' in T_ParamType'
            RAISERROR (@msg, 10, 1)
            return 51003
        end

        if @myRowCount = 0
        begin
            set @msg = 'Error updating T_ParamType; ParamID ' + @paramID + ' not found'
            RAISERROR (@msg, 10, 1)
            return 51003
        end

        UPDATE T_ParamType
        SET ParamName = @paramName,
            PicklistName = @paramPicklistName,
            Comment = @paramComment
        WHERE (ParamID = @paramID)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        if @myError <> 0
        begin
            set @msg = 'Error updating T_ParamType'
            RAISERROR (@msg, 10, 1)
            return 51003
        end

        If @paramNameCurrent <> @paramName
            Set @message = 'Warning: Parameter renamed from "' + @paramNameCurrent + '" to "' + @paramName + '"'
    end

    ---------------------------------------------------
    --
    ---------------------------------------------------

    return 0

GO
GRANT EXECUTE ON [dbo].[add_update_param_type] TO [Mgr_Config_Admin] AS [dbo]
GO
