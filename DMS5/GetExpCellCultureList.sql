/****** Object:  UserDefinedFunction [dbo].[GetExpCellCultureList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION GetExpCellCultureList
/****************************************************
**
**	Desc: 
**  Builds delimited list of cell cultures for
**  given experiment
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/4/2005
**    
*****************************************************/
(
@experimentNum varchar(50)
)
RETURNS varchar(1024)
AS
	BEGIN
		declare @list varchar(1024)
		set @list = ''
		
		SELECT 
			@list = @list + CASE 
								WHEN @list = '' THEN Cell_Culture_Name
								ELSE '; ' + Cell_Culture_Name
							END
		FROM V_Experiment_Cell_Culture WHERE Experiment_Num = @experimentNum
		
		if @list = '' set @list = '(none)'

		RETURN @list
	END

GO
