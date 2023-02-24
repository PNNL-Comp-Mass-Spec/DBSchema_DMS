/****** Object:  UserDefinedFunction [dbo].[get_long_interval_threshold] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_long_interval_threshold]
/****************************************************
**
**  Desc:
**  Returns threshold value (in minutes) for interval
**  to be considered a long interval
**
**  Return values:
**
**  Parameters:
**
**  Auth:   grk
**  Date:   06/08/2012 grk - initial release
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
()
RETURNS int
AS
    BEGIN
    RETURN 180
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_long_interval_threshold] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_long_interval_threshold] TO [DMS2_SP_User] AS [dbo]
GO
