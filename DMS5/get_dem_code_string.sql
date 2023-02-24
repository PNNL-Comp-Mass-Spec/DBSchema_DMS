/****** Object:  UserDefinedFunction [dbo].[GetDEMCodeString] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetDEMCodeString
/****************************************************
**
**	Desc: 
**  Returns sting for data extraction manager completion code
**  that have granted access to object
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 7/27/2006
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
GRANT VIEW DEFINITION ON [dbo].[GetDEMCodeString] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetDEMCodeString] TO [public] AS [dbo]
GO
