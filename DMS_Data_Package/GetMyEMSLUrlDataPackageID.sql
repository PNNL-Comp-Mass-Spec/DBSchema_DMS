/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLUrlDataPackageID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetMyEMSLUrlDataPackageID]
/****************************************************
**
**	Desc: 
**		Generates the MyEMSL URL required for viewing items stored for a given dataset
**		KeyName comes from https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
**
**	Auth:	mem
**	Date:	09/12/2013
**    
*****************************************************/
(
	@DataPackageID varchar(12)
)
RETURNS varchar(1024)
AS
BEGIN
	
	Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_datapackage.id'
	Declare @Url varchar(1024) = dbo.GetMyEMSLUrlWork(@KeyName, @DataPackageID)
	
	Return @Url
END


GO
