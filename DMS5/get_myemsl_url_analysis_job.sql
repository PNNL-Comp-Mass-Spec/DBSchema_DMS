/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLUrlAnalysisJob] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetMyEMSLUrlAnalysisJob
/****************************************************
**
**	Desc: 
**		Generates the MyEMSL URL required for viewing items stored for a given analysis job
**
**	Auth:	mem
**	Date:	09/12/2013
**    
*****************************************************/
(
	@JobResultsFolderName varchar(128)			-- For example, SIC201309120240_Auto978018
)
RETURNS varchar(1024)
AS
BEGIN
	Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_analysisjob.name.untouched'
	Declare @Url varchar(1024) = dbo.GetMyEMSLUrlWork(@KeyName, @JobResultsFolderName)
	
	Return @Url
END


GO
GRANT VIEW DEFINITION ON [dbo].[GetMyEMSLUrlAnalysisJob] TO [DDL_Viewer] AS [dbo]
GO
