/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLUrlDatasetName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetMyEMSLUrlDatasetName
/****************************************************
**
**	Desc: 
**		Generates the MyEMSL URL required for viewing items stored for a given dataset
**
**	Auth:	mem
**	Date:	09/12/2013
**    
*****************************************************/
(
	@DatasetName varchar(256)
)
RETURNS varchar(1024)
AS
BEGIN
	Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_dataset.name.untouched'
	Declare @Url varchar(1024) = dbo.GetMyEMSLUrlWork(@KeyName, @DatasetName)
	
	Return @Url
END

GO
