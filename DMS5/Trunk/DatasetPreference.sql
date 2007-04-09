/****** Object:  UserDefinedFunction [dbo].[DatasetPreference] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION DatasetPreference
/****************************************************
**
**	Desc: 
**		Determines if dataset name warrants  
**		preferential processing priority
**
**	Return values: 1 if preferred, 0 if not
**
**	Parameters:
**	
**
**	Auth:	grk
**	Date:	02/10/2006
**			04/09/2007 mem - Added matching of QC_Shew datasets in addition to QC datasets (Ticket #430)
**    
*****************************************************/
(
	@datasetNum varchar(128)
)
RETURNS tinyint
AS
	BEGIN
		declare @result tinyint
		set @result = 0
		if @datasetNum LIKE 'QC[_][0-9][0-9]%' or 
		   @datasetNum LIKE 'QC[_]Shew[_][0-9][0-9]%'
		begin
			set @result = 1
		end
	RETURN @result
	END

GO
GRANT EXECUTE ON [dbo].[DatasetPreference] TO [public]
GO
