/****** Object:  StoredProcedure [dbo].[GetAnalysisToolID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAnalysisToolID]
/****************************************************
**
**  Desc: Gets toolID for given dataset name
**
**  Return values: 0: failure, otherwise, dataset ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @toolName varchar(80) = " "
)
AS
    Set NoCount On

    Declare @toolID int = 0

    SELECT @toolID = AJT_toolID
    FROM T_Analysis_Tool
    WHERE AJT_toolName = @toolName

    return @toolID
GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisToolID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetAnalysisToolID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisToolID] TO [Limited_Table_Write] AS [dbo]
GO
