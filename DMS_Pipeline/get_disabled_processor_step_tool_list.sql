/****** Object:  UserDefinedFunction [dbo].[get_disabled_processor_step_tool_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_disabled_processor_step_tool_list]
/****************************************************
**
**  Desc:
**      Build a comma-separated list of disabled step tools for the given processor
**
**  Return value: delimited list
**
**  Auth:   mem
**  Date:   06/27/2024 mem - Initial version (based on get_processor_step_tool_list)
**
*****************************************************/
(
    @ProcessorName varchar(256)
)
RETURNS varchar(4000)
AS
    BEGIN
        Declare @list varchar(4000) = NULL

        SELECT @list = Coalesce(@list + ', ' + PTGD.Tool_Name, PTGD.Tool_Name)
        FROM T_Machines M
             INNER JOIN T_Local_Processors LP
               ON M.Machine = LP.Machine
             INNER JOIN T_Processor_Tool_Groups PTG
               ON M.ProcTool_Group_ID = PTG.Group_ID
             INNER JOIN T_Processor_Tool_Group_Details PTGD
               ON PTG.Group_ID = PTGD.Group_ID AND
                  LP.ProcTool_Mgr_ID = PTGD.Mgr_ID
        WHERE LP.Processor_Name = @ProcessorName AND (PTGD.Enabled <= 0)
        ORDER BY Tool_Name

        RETURN Coalesce(@list, '')
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_disabled_processor_step_tool_list] TO [DDL_Viewer] AS [dbo]
GO
