/****** Object:  StoredProcedure [dbo].[scan_instrument_source_folder] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[scan_instrument_source_folder]
/****************************************************
**  File:
**  Desc:
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   04/25/2002
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
**  NOTE: DO NOT USE IN 'Update' MODE
**  This is under development pending resolution
**  of access permissions issue inside xp_cmdshell
**
*****************************************************/
(
    @instrumentName varchar(64),
    @scanFileDir varchar(256) output,
    @mode varchar(12) = 'update', -- or ''
    @message varchar(512) output
)
AS
    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

--  set @message = ''

    declare @msg varchar(256)

    ---------------------------------------------------
    -- look up paths for scanner program
    ---------------------------------------------------
    declare @scanProgPath varchar(255)

    set @scanProgPath = ''
    --
    SELECT @scanProgPath = Server
    FROM T_MiscPaths
    WHERE ([Function] = 'InstrumentSourceScanProg')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @scanProgPath = ''
    begin
        set @msg = 'Could not get scan program path'
        RAISERROR (@msg, 10, 1)
        return 51007
    end

    set @scanFileDir = ''
    --
    SELECT @scanFileDir = Server
    FROM T_MiscPaths
    WHERE ([Function] = 'InstrumentSourceScanDir')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @scanProgPath = ''
    begin
        set @msg = 'could not get scan prog output dir'
        RAISERROR (@msg, 10, 1)
        return 51007
    end

    ---------------------------------------------------
    -- execute scanner (if mode is 'update')
    ---------------------------------------------------

    if @mode = 'update'
    begin
        declare @cmd varchar(256)
        declare @result int

        set @cmd =  @scanProgPath + ' ' + @instrumentName + ', '  + @scanFileDir

        exec @myError = master..xp_cmdshell @cmd
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[scan_instrument_source_folder] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[scan_instrument_source_folder] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[scan_instrument_source_folder] TO [Limited_Table_Write] AS [dbo]
GO
