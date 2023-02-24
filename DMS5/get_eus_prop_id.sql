/****** Object:  UserDefinedFunction [dbo].[get_eus_prop_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_eus_prop_id]
/****************************************************
**
**  Desc: Gets EUS Proposal ID for given EUS Proposal ID
**
**  Return values: 0: failure, otherwise, Proposal ID
**
**  Auth:   jds
**  Date:   09/01/2006
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @eusPropID varchar(10) = " "
)
RETURNS int
AS
BEGIN
    Declare @tempEUSPropID varchar(10) = '0'

    SELECT @tempEUSPropID = PROPOSAL_ID
    FROM T_EUS_Proposals
    WHERE PROPOSAL_ID = @EUSPropID

    return @tempEUSPropID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_eus_prop_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_eus_prop_id] TO [Limited_Table_Write] AS [dbo]
GO
