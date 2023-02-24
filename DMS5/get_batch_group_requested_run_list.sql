/****** Object:  UserDefinedFunction [dbo].[GetBatchGroupRequestedRunList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetBatchGroupRequestedRunList]
/****************************************************
**
**  Desc:
**      Builds a delimited list of the requested run IDs in a requested run batch group
**
**  Return value: Comma separated list
**
**  Auth:   mem
**  Date:   02/09/2023 mem - Initial version
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
GRANT VIEW DEFINITION ON [dbo].[GetBatchGroupRequestedRunList] TO [DDL_Viewer] AS [dbo]
GO
