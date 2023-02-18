/****** Object:  StoredProcedure [dbo].[StoreMyEMSLUploadStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[StoreMyEMSLUploadStats]
/****************************************************
**
**  Desc:
**      Store MyEMSL upload stats in T_MyEMSL_Uploads
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/25/2013 mem - Initial version
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          06/15/2017 mem - Add support for status URLs of the form https://ingestdms.my.emsl.pnl.gov/get_state?job_id=1305088
**          05/20/2019 mem - Add Set XACT_ABORT
**          10/13/2021 mem - Now using Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @DataPackageID int,
    @Subfolder varchar(128),
    @FileCountNew int,
    @FileCountUpdated int,
    @Bytes bigint,
    @UploadTimeSeconds real,
    @StatusURI varchar(255),
    @ErrorCode int,
    @message varchar(512)='' output,
    @infoOnly tinyint = 0
)
AS
    Declare @myError int = 0
    Exec @myError = store_myemsl_upload_stats @DataPackageID, @Subfolder, @FileCountNew, @FileCountUpdated, @Bytes, @UploadTimeSeconds, @StatusURI, @ErrorCode, @message output, @infoOnly
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[StoreMyEMSLUploadStats] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreMyEMSLUploadStats] TO [DMS_SP_User] AS [dbo]
GO
