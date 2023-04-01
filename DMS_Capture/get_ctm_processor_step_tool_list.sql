/****** Object:  UserDefinedFunction [dbo].[get_processor_step_tool_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_processor_step_tool_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of step tools for the given processor
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/30/2009
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @processorName varchar(256)
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @list varchar(4000)
        set @list = ''

        SELECT
            @list = CASE WHEN @list = '' THEN Tool_Name ELSE @list + ', ' + Tool_Name END
        FROM dbo.T_Processor_Tool
        WHERE Processor_Name = @ProcessorName AND (Enabled > 0)
        ORDER BY Tool_Name

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_processor_step_tool_list] TO [DDL_Viewer] AS [dbo]
GO
