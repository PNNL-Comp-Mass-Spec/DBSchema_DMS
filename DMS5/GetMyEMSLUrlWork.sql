/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLUrlWork] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetMyEMSLUrlWork
/****************************************************
**
**	Desc: 
**		Generates the MyEMSL URL required for viewing items in MyEMSL
**
**	Auth:	mem
**	Date:	09/12/2013
**    
*****************************************************/
(
	@KeyName varchar(128),
	@Value varchar(256)
)
RETURNS varchar(1024)
AS
BEGIN
	-- Valid key names are defined in https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
	-- They include:
	--   extended_metadata.gov_pnnl_emsl_dms_analysisjob.name.untouched
	--   extended_metadata.gov_pnnl_emsl_dms_analysisjob.tool.name.untouched
	--   extended_metadata.gov_pnnl_emsl_dms_campaign.name.untouched
	--   extended_metadata.gov_pnnl_emsl_dms_datapackage.name.untouched
	--   extended_metadata.gov_pnnl_emsl_dms_dataset.name.untouched
	--   extended_metadata.gov_pnnl_emsl_dms_experiment.name.untouched
	--   extended_metadata.gov_pnnl_emsl_instrument.name.untouched
	--   ext  (filename extension)

	Declare @Json varchar(1024)
	Set @Json = '{ "pacifica-search-simple": { "v": 1, "facets_set": [{"key": "' + @KeyName + '", "value":"' + @Value + '"}] } }'

	Declare @EncodedText varchar(1024) = dbo.EncodeBase64(@Json)
	
	Declare @Url varchar(1024) = 'https://my.emsl.pnl.gov/myemsl/search/simple/' + @EncodedText
	
	Return @URL
END

GO
