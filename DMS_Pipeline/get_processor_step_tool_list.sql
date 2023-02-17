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
**          09/02/2009 mem - Now using T_Processor_Tool_Groups and T_Processor_Tool_Group_Details to determine the processor tool priorities for the given processor
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @ProcessorName varchar(256)
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @list varchar(4000)
        set @list = NULL

        SELECT @list = Coalesce(@list + ', ' + PTGD.Tool_Name, PTGD.Tool_Name)
        FROM T_Machines M
             INNER JOIN T_Local_Processors LP
               ON M.Machine = LP.Machine
             INNER JOIN T_Processor_Tool_Groups PTG
               ON M.ProcTool_Group_ID = PTG.Group_ID
             INNER JOIN T_Processor_Tool_Group_Details PTGD
               ON PTG.Group_ID = PTGD.Group_ID AND
                  LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
        WHERE LP.Processor_Name = @ProcessorName AND (PTGD.Enabled > 0)
        ORDER BY Tool_Name

        If @list Is Null
            Set @list = ''

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_processor_step_tool_list] TO [DDL_Viewer] AS [dbo]
GO
