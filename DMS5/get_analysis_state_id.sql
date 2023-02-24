/****** Object:  StoredProcedure [dbo].[GetAnalysisStateID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetAnalysisStateID]
/****************************************************
**
**  Desc: Gets Analysis Job state ID for given state name
**
**  Return values: 0: failure, otherwise, instrument ID
**
**  Auth:   grk
**  Date:   01/15/2005
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @analysisJobStateName varchar(32) = " "
)
AS
    Set NoCount On

    Declare @stateID int = 0

    SELECT @stateID = AJS_stateID
    FROM T_Analysis_State_Name
    WHERE AJS_name = @analysisJobStateName

    return @stateID

GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisStateID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisStateID] TO [Limited_Table_Write] AS [dbo]
GO
