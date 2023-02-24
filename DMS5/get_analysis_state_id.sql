/****** Object:  UserDefinedFunction [dbo].[get_analysis_state_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_analysis_state_id]
/****************************************************
**
**  Desc: Gets Analysis Job state ID for given state name
**
**  Return values: 0: failure, otherwise, instrument ID
**
**  Auth:   grk
**  Date:   01/15/2005
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @analysisJobStateName varchar(32) = " "
)
RETURNS int
AS
BEGIN
    Declare @stateID int = 0

    SELECT @stateID = AJS_stateID
    FROM T_Analysis_State_Name
    WHERE AJS_name = @analysisJobStateName

    return @stateID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_analysis_state_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_analysis_state_id] TO [Limited_Table_Write] AS [dbo]
GO
