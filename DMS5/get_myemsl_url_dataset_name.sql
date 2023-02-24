/****** Object:  UserDefinedFunction [dbo].[get_myemsl_url_dataset_name] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_myemsl_url_dataset_name]
/****************************************************
**
**  Desc:
**      Generates the MyEMSL URL required for viewing items stored for a given dataset
**
**  Auth:   mem
**  Date:   09/12/2013
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(256)
)
RETURNS varchar(1024)
AS
BEGIN
    Declare @KeyName varchar(128) = 'extended_metadata.gov_pnnl_emsl_dms_dataset.name.untouched'
    Declare @Url varchar(1024) = dbo.get_myemsl_url_work(@KeyName, @DatasetName)

    Return @Url
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_myemsl_url_dataset_name] TO [DDL_Viewer] AS [dbo]
GO
