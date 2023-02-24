/****** Object:  UserDefinedFunction [dbo].[get_batch_dataset_instrument_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_batch_dataset_instrument_list]
/****************************************************
**
**  Desc:
**      Builds delimited list of instruments for the datasets
**      associated with the given requested run batch
**
**  Return value: delimited list
**
**  Auth:   mem
**  Date:   08/29/2010 mem - Initial version
**          03/29/2019 mem - Return an empty string when @batchID is 0 (meaning "unassigned", no batch)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @batchID int
)
RETURNS varchar(4000)
AS
BEGIN
    Declare @list varchar(4000) = ''

    SELECT @list = @list + CASE
                               WHEN @list = '' THEN Instrument
                               ELSE ', ' + Instrument
                           END
    FROM ( SELECT DISTINCT InstName.IN_name AS Instrument
           FROM T_Requested_Run RR
                INNER JOIN T_Dataset DS
                  ON RR.DatasetID = DS.Dataset_ID
                INNER JOIN T_Instrument_Name InstName
                  ON DS.DS_instrument_name_ID = InstName.Instrument_ID
           WHERE RR.RDS_BatchID = @batchID AND RR.RDS_BatchID <> 0
          ) LookupQ
    ORDER BY Instrument

    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_batch_dataset_instrument_list] TO [DDL_Viewer] AS [dbo]
GO
