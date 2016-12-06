/****** Object:  UserDefinedFunction [dbo].[DatasetPreference] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.DatasetPreference
/****************************************************
**
**	Desc: 
**		Determines if dataset name warrants preferential processing priority
**		This procedure is used by AddNewDataset to auto-release QC_Shew datasets
**		(if either the dataset name or the experiment name matches one of the
**		 filters below, the Interest_Rating is set to 5 (Released)
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
**			05/12/2011 mem - Now excluding datasets that end in -bad
**			01/16/2014 mem - Added QC_ShewIntact datasets
**			12/18/2014 mem - Replace [_] with [_-]
**			05/07/2015 mem - Added QC_Shew_TEDDY
**    
*****************************************************/
(
	@datasetNum varchar(128)
)
RETURNS tinyint
AS
BEGIN
	declare @result tinyint

	IF (@datasetNum LIKE 'QC[_][0-9][0-9]%' OR
	    @datasetNum LIKE 'QC[_-]Shew[_-][0-9][0-9]%' OR
	    @datasetNum LIKE 'QC[_-]ShewIntact%' OR
	    @datasetNum LIKE 'QC[_]Shew[_]TEDDY%') AND
	    NOT @datasetNum LIKE '%-bad'
	    SET @result = 1
	ELSE
	    SET @result = 0
	
	RETURN @result
END


GO
GRANT VIEW DEFINITION ON [dbo].[DatasetPreference] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DatasetPreference] TO [public] AS [dbo]
GO
