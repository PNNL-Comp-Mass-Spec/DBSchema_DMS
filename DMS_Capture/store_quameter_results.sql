/****** Object:  StoredProcedure [dbo].[store_quameter_results] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[store_quameter_results]
/****************************************************
**
**  Desc:
**      Store Quameter results by calling s_store_quameter_results
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetID int = 0,             -- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
    @resultsXML xml,                -- XML holding the Quameter results for a single dataset
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'store_quameter_results', @raiseError = 1;
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    exec @myError = s_store_quameter_results @DatasetID=@DatasetID, @ResultsXML=@ResultsXML, @message=@message output, @infoOnly=@infoOnly

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[store_quameter_results] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[store_quameter_results] TO [DMS_SP_User] AS [dbo]
GO
