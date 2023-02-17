/****** Object:  StoredProcedure [dbo].[StoreQuameterResults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.StoreQuameterResults
/****************************************************
**
**  Desc:
**      Store Quameter results by calling S_StoreQuameterResults
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/17/2012 mem - Initial version
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**
*****************************************************/
(
    @DatasetID int = 0,             -- If this value is 0, then will determine the dataset name using the contents of @ResultsXML
    @ResultsXML xml,                -- XML holding the Quameter results for a single dataset
    @message varchar(255) = '' output,
    @infoOnly tinyint = 0
)
As
    set nocount on

    declare @myError int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'StoreQuameterResults', @raiseError = 1;
    If @authorized = 0
    Begin
        THROW 51000, 'Access denied', 1;
    End

    exec @myError = S_StoreQuameterResults @DatasetID=@DatasetID, @ResultsXML=@ResultsXML, @message=@message output, @infoOnly=@infoOnly

    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[StoreQuameterResults] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[StoreQuameterResults] TO [DMS_SP_User] AS [dbo]
GO
