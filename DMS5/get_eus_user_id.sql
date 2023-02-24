/****** Object:  StoredProcedure [dbo].[GetEUSUserID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetEUSUserID]
/****************************************************
**
**  Desc: Gets EUS User ID for given EUS User ID
**
**  Return values: 0: failure, otherwise, EUS User ID
**
**  Auth:   jds
**  Date:   09/01/2006
**          08/03/2017 mem - Add Set NoCount On
**
*****************************************************/
(
    @EUSUserID varchar(32) = " "
)
AS
    Set NoCount On

    Declare @tempEUSUserID varchar(32) = '0'

    SELECT @tempEUSUserID = PERSON_ID
    FROM T_EUS_Users
    WHERE PERSON_ID = @EUSUserID

    return @tempEUSUserID

GO
GRANT VIEW DEFINITION ON [dbo].[GetEUSUserID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetEUSUserID] TO [Limited_Table_Write] AS [dbo]
GO
