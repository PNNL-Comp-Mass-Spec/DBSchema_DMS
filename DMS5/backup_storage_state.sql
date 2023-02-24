/****** Object:  StoredProcedure [dbo].[BackUpStorageState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[BackUpStorageState]
/****************************************************
**
**  Desc:
**      Copies current contents of storage and
**      instrument tables into their backup tables
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
**
*****************************************************/
(
    @message varchar(255) output
)
AS
    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- Clear T_Storage_Path_Bkup
    ---------------------------------------------------

    DELETE FROM T_Storage_Path_Bkup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Clear storage backup table failed'
        return 1
    end

    ---------------------------------------------------
    -- Populate T_Storage_Path_Bkup
    ---------------------------------------------------

    INSERT INTO T_Storage_Path_Bkup
       (SP_path_ID, SP_path, SP_vol_name_client,
       SP_vol_name_server, SP_function, SP_instrument_name,
       SP_code, SP_description)
    SELECT SP_path_ID, SP_path, SP_vol_name_client,
       SP_vol_name_server, SP_function, SP_instrument_name,
       SP_code, SP_description
    FROM T_Storage_Path
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    --
    if @myError <> 0
    begin
        set @message = 'Copy storage backup failed'
        return 1
    end

    ---------------------------------------------------
    -- Clear T_Instrument_Name_Bkup
    ---------------------------------------------------

    DELETE FROM T_Instrument_Name_Bkup
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    --
    if @myError <> 0
    begin
        set @message = 'Clear instrument backup table failed'
        return 1
    end

    ---------------------------------------------------
    -- Populate T_Instrument_Name_Bkup
    ---------------------------------------------------

    INSERT INTO [T_Instrument_Name_Bkup]
       (IN_name, Instrument_ID, IN_class, IN_source_path_ID,
       IN_storage_path_ID, IN_capture_method,
       IN_Room_Number,
       IN_Description,
       IN_Created)
    SELECT IN_name,
           Instrument_ID,
           IN_class,
           IN_source_path_ID,
           IN_storage_path_ID,
           IN_capture_method,
           IN_Room_Number,
           IN_Description,
           IN_Created
    FROM T_Instrument_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    --
    if @myError <> 0
    begin
        set @message = 'Copy instrument backup failed'
        return 1
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[BackUpStorageState] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[BackUpStorageState] TO [Limited_Table_Write] AS [dbo]
GO
