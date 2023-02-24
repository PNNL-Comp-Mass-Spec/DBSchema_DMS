/****** Object:  UserDefinedFunction [dbo].[get_lc_config_docs_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_lc_config_docs_path]
/****************************************************
**
**  Desc:
**       Get path to LC config file
**
**  Return values: {path}: success, otherwise, {''}
**                 @storagePath contains path
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/17/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @cartName varchar(128),
    @suffix varchar(32)
)
RETURNS varchar(1024)
AS
    BEGIN
    declare @result varchar(256)
    set @result = ''

    declare @path varchar(256)
    set @path = ''
    --
    SELECT @path = Client
    FROM T_MiscPaths
    WHERE [Function] = 'LCCartConfigDocs'

    if @path <> ''
    begin
        set @result = '<a href="' + @path + @cartName + @suffix + '" >' + @cartName + @suffix + '</a>'
    end

    return @result
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_lc_config_docs_path] TO [DDL_Viewer] AS [dbo]
GO
