/****** Object:  StoredProcedure [dbo].[CacheDatasetInfoXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CacheDatasetInfoXML]
/****************************************************
**
**  Desc:   Caches the XML-based dataset info in table T_Dataset_Info_XML
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   05/03/2010 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetID int,
    @datasetInfoXML xml,
    @message varchar(255) = '' output
)
AS
    set nocount on

    declare @myError int = 0
    EXEC @myError = cache_dataset_info_xml @datasetID, @datasetInfoXML, @message output
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[CacheDatasetInfoXML] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[CacheDatasetInfoXML] TO [DMS_SP_User] AS [dbo]
GO
