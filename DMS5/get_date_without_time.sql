/****** Object:  UserDefinedFunction [dbo].[get_date_without_time] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_date_without_time]
/****************************************************
**
**  Desc:
**      Rounds the date portion of @Date
**      Dates are truncated, not rounded
**
**  Auth:   mem
**  Date:   09/11/2012
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @date Datetime
)
RETURNS Datetime
AS
BEGIN
    Declare @NewDate Datetime
    Set @NewDate = floor(convert(float, @Date))

    Return @NewDate
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_date_without_time] TO [DDL_Viewer] AS [dbo]
GO
