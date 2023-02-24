/****** Object:  UserDefinedFunction [dbo].[get_dem_code_string] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dem_code_string]
/****************************************************
**
**  Desc:
**  Returns sting for data extraction manager completion code
**  that have granted access to object
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   07/27/2006
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @code smallint
)
RETURNS varchar(64)
AS
    BEGIN
        declare @description varchar(64)
        set @description = case @code
                            when 0 then 'Success'
                            when 1 then 'Failed'
                            when 2 then 'No Param File'
                            when 3 then 'No Settings File'
                            when 5 then 'No Moddefs File'
                            when 6 then 'No MassCorrTag File'
                            when 10 then 'No Data'
                            end
        RETURN @description + ' (' + cast(@code as varchar(10)) + ')'
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dem_code_string] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dem_code_string] TO [public] AS [dbo]
GO
