/****** Object:  UserDefinedFunction [dbo].[get_dataset_myemsl_transaction_ids] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_myemsl_transaction_ids]
/****************************************************
**
**  Desc: Returns a comma separated list of the MyEMSL ingest transaction IDs for this dataset ID
**
**  Auth:   mem
**  Date:   02/28/2018 mem - Initial version
**          02/03/2023 bcg - Update column names for S_V_MyEMSL_DatasetID_TransactionID
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
                               WHEN @list = '' THEN Cast(Transaction_ID AS varchar(12))
                               ELSE ', ' + Cast(Transaction_ID AS varchar(12))
                           END
    FROM S_V_MyEMSL_DatasetID_TransactionID
    WHERE Dataset_ID = @datasetID AND
          Verified > 0

    RETURN IsNull(@list, '')
END

GO
