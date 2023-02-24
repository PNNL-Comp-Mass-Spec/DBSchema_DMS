/****** Object:  UserDefinedFunction [dbo].[get_batch_group_requested_run_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_batch_group_requested_run_list]
/****************************************************
**
**  Desc:
**      Builds a delimited list of the requested run IDs in a requested run batch group
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
                               WHEN @list = '' THEN cast(RR.ID as varchar(12))
                               ELSE ', ' + cast(RR.ID as varchar(12))
                           END
    FROM T_Requested_Run_Batches RRB
         INNER JOIN t_requested_run RR
           ON RR.RDS_BatchID = RRB.ID
    WHERE RRB.Batch_Group_ID = @batchGroupID
    ORDER BY RR.ID

    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_batch_group_requested_run_list] TO [DDL_Viewer] AS [dbo]
GO
