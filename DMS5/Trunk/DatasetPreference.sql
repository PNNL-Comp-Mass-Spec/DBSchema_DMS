/****** Object:  UserDefinedFunction [dbo].[DatasetPreference] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.DatasetPreference
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
**			04/11/2008 mem - Added matching of SE_QC_Shew datasets in addition to QC datasets
**    
*****************************************************/
(
	@datasetNum varchar(128)
)
RETURNS tinyint
AS
	BEGIN
		declare @result tinyint
	
		if @datasetNum LIKE 'QC[_][0-9][0-9]%' OR 
		   @datasetNum LIKE 'QC[_]Shew[_][0-9][0-9]%' OR 
		   @datasetNum LIKE 'SE_QC[_]Shew[_][0-9][0-9]%'
			set @result = 1
		else
			set @result = 0
		
	RETURN @result
	END


GO
GRANT EXECUTE ON [dbo].[DatasetPreference] TO [public] AS [dbo]
GO
