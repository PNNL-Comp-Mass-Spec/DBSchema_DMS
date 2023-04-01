/****** Object:  UserDefinedFunction [dbo].[get_job_script_graphic_cmd_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_job_script_graphic_cmd_list]
/****************************************************
**  Returns Dot graphic commnd list for given script
**
**  Auth:   grk
**  Date:   09/08/2009
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/05/2023 mem - Use new view name
**
****************************************************/
(
    @script VARCHAR(256)
)
RETURNS VARCHAR(4096)
AS
    BEGIN
        DECLARE @s VARCHAR(4096)
        SET @s = ''
        --
        SELECT @s = @s + line
        FROM dbo.V_Capture_Script_Dot_Format
        WHERE Script = @script
        ORDER BY seq
        --
        RETURN @s
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_script_graphic_cmd_list] TO [DDL_Viewer] AS [dbo]
GO
