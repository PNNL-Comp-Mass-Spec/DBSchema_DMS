/****** Object:  UserDefinedFunction [dbo].[get_batch_group_instrument_group_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_batch_group_instrument_group_list]
/****************************************************
**
**  Desc:
**      Builds a delimited list of the instrument groups associated with a requested run batch group
**      These are based on instrument group names in T_Requested_Run
**
**  Return value: Comma separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          01/19/2024 mem - Obtain instrument group names from T_Requested_Run
**
*****************************************************/
(
    @batchGroupID int
)
RETURNS varchar(max)
AS
BEGIN
    Declare @list varchar(max) = ''

    SELECT @list = @list + CASE
                               WHEN @list = '' THEN LookupQ.Requested_Instrument_Group
                               ELSE ', ' + LookupQ.Requested_Instrument_Group
                           END
    FROM ( SELECT DISTINCT RR.RDS_instrument_group AS Requested_Instrument_Group
           FROM T_Requested_Run_Batches RRB
                LEFT OUTER JOIN T_Requested_Run RR
                  ON RRB.ID = RR.RDS_BatchID
           WHERE RRB.Batch_Group_ID = @batchGroupID) LookupQ
    ORDER BY LookupQ.Requested_Instrument_Group;

    RETURN @list
END

GO
