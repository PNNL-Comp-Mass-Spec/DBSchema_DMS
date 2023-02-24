/****** Object:  UserDefinedFunction [dbo].[GetBatchGroupMemberList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetBatchGroupMemberList]
/****************************************************
**
**  Desc:
**      Builds a delimited list of batch IDs in a requested run batch group
**      Batch IDs are sorted by Batch_Group_Order
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
                               WHEN @list = '' THEN cast(ID as varchar(12))
                               ELSE ', ' + cast(ID as varchar(12))
                           END
    FROM T_Requested_Run_Batches
    WHERE Batch_Group_ID = @batchGroupID
    ORDER BY Coalesce(Batch_Group_Order, 0), ID

    RETURN @list
END


GO
GRANT VIEW DEFINITION ON [dbo].[GetBatchGroupMemberList] TO [DDL_Viewer] AS [dbo]
GO
