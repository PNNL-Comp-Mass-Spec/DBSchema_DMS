/****** Object:  UserDefinedFunction [dbo].[get_analysis_tool_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_analysis_tool_id]
/****************************************************
**
**  Desc: Gets toolID for given dataset name
**
**  Return values: 0: failure, otherwise, dataset ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @toolName varchar(80) = " "
)
RETURNS int
AS
BEGIN
    Declare @toolID int = 0

    SELECT @toolID = AJT_toolID
    FROM T_Analysis_Tool
    WHERE AJT_toolName = @toolName

    return @toolID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_analysis_tool_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_analysis_tool_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_analysis_tool_id] TO [Limited_Table_Write] AS [dbo]
GO
