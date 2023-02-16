/****** Object:  UserDefinedFunction [dbo].[get_myemsl_url_data_package_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_myemsl_url_data_package_name]
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given dataset
**      KeyName comes from https://my.emsl.pnl.gov/myemsl/api/1/elasticsearch/generic-finder.js
**
**  Auth:   mem
**  Date:   09/24/2013
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @dataPackageName varchar(1024)
)
RETURNS varchar(1024)
AS
BEGIN
    Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_datapackage.name.untouched'
    Declare @Url varchar(1024) = dbo.get_myemsl_url_work(@KeyName, @DataPackageName)

    Return @Url
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_myemsl_url_data_package_name] TO [DDL_Viewer] AS [dbo]
GO
