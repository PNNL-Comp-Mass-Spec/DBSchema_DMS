/****** Object:  UserDefinedFunction [dbo].[validate_na_parameter] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[validate_na_parameter]
/****************************************************
**
**  Desc:   Makes sure that the parameter text is 'na' if blank or null, or if it matches 'na' or 'n/a'
**          Note that Sql server string comparisons are not case-sensitive, but VB.NET string comparisons are
**          Therefore, this function makes sure @parameter is lowercase 'na', when blank, null, 'na', or 'n/a'
**
**  Returns the validated parameter
**
**  Auth:   mem
**  Date:   09/12/2008 mem - Ticket #688, http://prismtrac.pnl.gov/trac/ticket/688
**          01/14/2009 mem - Expanded @parameter length to 4000 characters (Ticket #714, http://prismtrac.pnl.gov/trac/ticket/714)
**          03/10/2021 mem - Ported to the DMS_Pipeline database
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @parameter varchar(4000)
)
    RETURNS varchar(4000)
AS
Begin
    Set @parameter = LTrim(RTrim(IsNull(@parameter, 'na')))

    If @parameter = ''
        Set @parameter = 'na'

    If Lower(@parameter) = 'na' or Lower(@parameter) = 'n/a'
        Set @parameter = 'na'

    Return @parameter
End

GO
