/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLUrlDataPackageName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetMyEMSLUrlDataPackageName]
/****************************************************
**
**	Desc: 
**		Generates the MyEMSL URL required for viewing items stored for a given dataset
**		KeyName comes from https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
**
**	Auth:	mem
**	Date:	09/24/2013
**    
*****************************************************/
(
	@DataPackageName varchar(1024)
)
RETURNS varchar(1024)
AS
BEGIN
	Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_datapackage.name.untouched'
	Declare @Url varchar(1024) = dbo.GetMyEMSLUrlWork(@KeyName, @DataPackageName)
	
	Return @Url
END


GO
