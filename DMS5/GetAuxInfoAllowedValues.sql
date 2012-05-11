/****** Object:  UserDefinedFunction [dbo].[GetAuxInfoAllowedValues] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION GetAuxInfoAllowedValues
/****************************************************
**
**	Desc: 
**  Builds delimited list of allowed values for given aux info item
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 08/24/2010
**    
*****************************************************/
(
@ID int
)
RETURNS varchar(1024)
AS
	BEGIN
		declare @list varchar(1024)
		set @list = ''
		
		SELECT 
 			@list = @list + CASE 
								WHEN @list = '' THEN Value
								ELSE ' | ' + Value
							END
			FROM T_AuxInfo_Allowed_Values
			WHERE AuxInfoID = @ID

		RETURN @list
	END
GO
GRANT EXECUTE ON [dbo].[GetAuxInfoAllowedValues] TO [DMS2_SP_User] AS [dbo]
GO
