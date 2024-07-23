/****** Object:  StoredProcedure [dbo].[backup_storage_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[backup_storage_state]
/****************************************************
**
**  Desc:
**      Copy current contents of storage and instrument tables into their backup tables
**
**  Return values: 0: failure, otherwise, experiment ID
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/18/2002
**          04/07/2006 grk - Got rid of CDBurn stuff
**          05/01/2009 mem - Updated description field in T_Storage_Path and T_Storage_Path_Bkup to be named SP_description
**          08/30/2010 mem - Now copying IN_Created
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          07/23/2024 mem - Also copy data from columns IN_Group and IN_status
**
*****************************************************/
(
    @message varchar(255) output
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Clear T_Storage_Path_Bkup
    ---------------------------------------------------

    DELETE FROM T_Storage_Path_Bkup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Clear storage backup table failed'
        Return @myError
    End

    ---------------------------------------------------
    -- Populate T_Storage_Path_Bkup
    ---------------------------------------------------

    INSERT INTO T_Storage_Path_Bkup (
       SP_path_ID,
       SP_path,
       SP_vol_name_client,
       SP_vol_name_server,
       SP_function,
       SP_instrument_name,
       SP_code,
       SP_description
    )
    SELECT SP_path_ID,
           SP_path,
           SP_vol_name_client,
           SP_vol_name_server,
           SP_function,
           SP_instrument_name,
           SP_code,
           SP_description
    FROM T_Storage_Path
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Copy storage backup failed'
        Return @myError
    End

    ---------------------------------------------------
    -- Clear T_Instrument_Name_Bkup
    ---------------------------------------------------

    DELETE FROM T_Instrument_Name_Bkup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Clear instrument backup table failed'
        Return @myError
    End

    ---------------------------------------------------
    -- Populate T_Instrument_Name_Bkup
    ---------------------------------------------------

    INSERT INTO T_Instrument_Name_Bkup (
        Instrument_ID,
        IN_name,
        IN_class,
        IN_Group,
        IN_source_path_ID,
        IN_storage_path_ID,
        IN_capture_method,
        IN_status,
        IN_Room_Number,
        IN_Description,
        IN_Created
    )
    SELECT Instrument_ID,
           IN_name,
           IN_class,
           IN_Group,
           IN_source_path_ID,
           IN_storage_path_ID,
           IN_capture_method,
           IN_status,
           IN_Room_Number,
           IN_Description,
           IN_Created
    FROM T_Instrument_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Copy instrument backup failed'
        Return @myError
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[backup_storage_state] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[backup_storage_state] TO [Limited_Table_Write] AS [dbo]
GO
