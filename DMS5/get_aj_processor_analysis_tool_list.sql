/****** Object:  UserDefinedFunction [dbo].[get_aj_processor_analysis_tool_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_aj_processor_analysis_tool_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of analysis tools
**  for given analysis job processor ID
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/23/2007 (Ticket 389)
**          03/15/2007 mem - Increased size of @list to varchar(4000); now ordering by tool name
**          03/30/2009 mem - Now using Coalesce to generate the comma separated list
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @processorID int
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @list varchar(4000)
        set @list = NULL

        SELECT @list = Coalesce(@list + ', ' + T.AJT_toolName, T.AJT_toolName)
        FROM T_Analysis_Job_Processor_Tools AJPT INNER JOIN
             T_Analysis_Tool T ON AJPT.Tool_ID = T.AJT_toolID
        WHERE (AJPT.Processor_ID = @processorID)
        ORDER BY T.AJT_toolName

        If @list Is Null
            Set @list = ''

        RETURN @list
    END

GO
GRANT EXECUTE ON [dbo].[get_aj_processor_analysis_tool_list] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_aj_processor_analysis_tool_list] TO [DDL_Viewer] AS [dbo]
GO
