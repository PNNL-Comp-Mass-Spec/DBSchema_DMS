/****** Object:  UserDefinedFunction [dbo].[get_eus_user_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_eus_user_id]
/****************************************************
**
**  Desc: Gets EUS User ID for given EUS User ID
**
**  Return values: 0: failure, otherwise, EUS User ID
**
**  Auth:   jds
**  Date:   09/01/2006
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @eusUserID varchar(32) = " "
)
RETURNS int
AS
BEGIN
    Declare @tempEUSUserID varchar(32) = '0'

    SELECT @tempEUSUserID = PERSON_ID
    FROM T_EUS_Users
    WHERE PERSON_ID = @EUSUserID

    return @tempEUSUserID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_eus_user_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_eus_user_id] TO [Limited_Table_Write] AS [dbo]
GO
