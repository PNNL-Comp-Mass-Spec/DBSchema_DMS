/****** Object:  UserDefinedFunction [dbo].[GetMyEMSLTransactionIdURLs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetMyEMSLTransactionIdURLs]
/****************************************************
**
**  Desc: Returns a comma separated list of the URLs 
**  to view files associated with each transaction IDs for this dataset ID
**
**  Auth:   mem
**  Date:   02/28/2018 mem - Initial version
**    
*****************************************************/
(
    @datasetID INT
)
RETURNS varchar(3500)
AS
BEGIN
    DECLARE @list varchar(3500) = ''

    SELECT @list = @list + CASE
                               WHEN @list = '' THEN 'https://status.my.emsl.pnl.gov/view/' + Cast(TransactionID AS varchar(12))
                               ELSE ', https://status.my.emsl.pnl.gov/view/' + Cast(TransactionID AS varchar(12))
                           END
    FROM S_V_MyEMSL_DatasetID_TransactionID
    WHERE Dataset_ID = @datasetID AND
          Verified > 0
    ORDER BY TransactionID

    RETURN IsNull(@list, '')
END

GO
