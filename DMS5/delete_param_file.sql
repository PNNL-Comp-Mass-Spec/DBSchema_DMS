/****** Object:  StoredProcedure [dbo].[delete_param_file] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[delete_param_file]
/****************************************************
**
**  Desc: Deletes given Sequest Param file from the T_Param_Files
**        and all referencing tables
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   07/22/2004 mem
**          02/12/2010 mem - Now updating @message when the parameter file is successfully deleted
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @paramFileName varchar(255),
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int = 0
    declare @myRowCount int = 0

    set @message = ''

    declare @msg varchar(256)

    declare @ParamFileID int
--  declare @state int

    declare @result int

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'delete_param_file', @raiseError = 1
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    ---------------------------------------------------
    -- get ParamFileID
    ---------------------------------------------------

    SELECT
        @ParamFileID = Param_File_ID
    FROM T_Param_Files
    WHERE (Param_File_Name = @ParamFileName)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @msg = 'Could not get ID for Param File "' + @ParamFileName + '"'
        print @msg
        RAISERROR (@msg, 10, 1)
        return 51140
    end

    If @myRowCount = 0
    Begin
        set @msg = 'Param file not found in T_Param_Files: ' + @ParamFileName
        print @msg
        RAISERROR (@msg, 10, 1)
        return 51141
    End

    execute @result = delete_param_file_by_id @ParamFileID, @msg output

    If @result = 0
    Begin
        Set @message = 'Deleted parameter file ' + @ParamFileName
        Print @message
    End

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[delete_param_file] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[delete_param_file] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[delete_param_file] TO [Limited_Table_Write] AS [dbo]
GO
