/****** Object:  UserDefinedFunction [dbo].[ExpSampleLocation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[ExpSampleLocation]
/****************************************************
**
**	Desc: 
**		converts any location auxiliary info to location
**		for given experiment
**
**	Return values: location as string
**
**	Parameters:
**	
**
**	Auth:	grk
**	Date:	02/26/2004
**			10/31/2007 mem - Added "ORDER BY" for migration to SS2005 (ticket #226)
**    
*****************************************************/
(
	@exp_ID int
)
RETURNS varchar(256)
AS
BEGIN
	declare @loc varchar(1024)
	set @loc = ''

	SELECT     @loc = @loc + Item +':' + Value + ', ' 
	FROM V_AuxInfo_Value
	WHERE (Target = 'experiment') AND 
		  (Category = 'Storage') AND 
		  (Subcategory = 'location') AND 
		  (Target_ID = @exp_ID)
	ORDER BY SC, SS, SI

	RETURN @loc
END


GO
GRANT EXECUTE ON [dbo].[ExpSampleLocation] TO [public] AS [dbo]
GO
