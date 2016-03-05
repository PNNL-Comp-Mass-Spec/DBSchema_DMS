/****** Object:  UserDefinedFunction [dbo].[GetTaxIDTaxonomyList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetTaxIDTaxonomyList
/****************************************************
**
**	Desc:	Builds a delimited list of taxonomy information
**
**	Return value: List of items separated by vertical bars
**
**		Rank:Name:Tax_ID|Rank:Name:Tax_ID|Rank:Name:Tax_ID|
**
**	Auth:	mem
**	Date:	03/02/2016 mem - Initial version
**			03/03/2016 mem - Added @ExtendedInfo
**    
*****************************************************/
(
	@TaxonomyID int,
	@ExtendedInfo tinyint
)
RETURNS varchar(4000)
AS
BEGIN
	Declare @list varchar(4000) = ''
	
	SELECT @list = @list + '|' + 
	               [Rank] + ':' + 
	               [Name]
	FROM dbo.GetTaxIDTaxonomyTable ( @TaxonomyID )
	WHERE Entry_ID = 1 OR
	      [Rank] <> 'no rank' OR
	      @ExtendedInfo > 0
	ORDER BY Entry_ID Desc
	
	Return Substring(@list, 2, 4000)
	
END


GO
GRANT EXECUTE ON [dbo].[GetTaxIDTaxonomyList] TO [DMSReader] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetTaxIDTaxonomyList] TO [DMSWebUser] AS [dbo]
GO
