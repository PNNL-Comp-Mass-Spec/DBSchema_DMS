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
**      These are based on instrument group names in t_requested_run_batches
**
**  Return value: Comma separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
                               WHEN @list = '' THEN LookupQ.Requested_Instrument
                               ELSE ', ' + LookupQ.Requested_Instrument
                           END
    FROM ( SELECT DISTINCT RRB.Requested_Instrument
           FROM T_Requested_Run_Batches RRB
           WHERE RRB.Batch_Group_ID = @batchGroupID) LookupQ
    ORDER BY LookupQ.Requested_Instrument;

    RETURN @list
END

GO
