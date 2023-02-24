/****** Object:  UserDefinedFunction [dbo].[jobs_in_batch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[jobs_in_batch]
/****************************************************
**
**  Desc:
**      returns count of number of jobs in given batch
**
**
**  Auth:   grk
**  Date:   02/27/2004
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @batchID int
)
RETURNS int
AS
    BEGIN
        declare @n int
        SELECT     @n = COUNT(*)
        FROM         T_Analysis_Job
        WHERE     (AJ_batchID = @batchID)

        RETURN @n
    END

GO
GRANT VIEW DEFINITION ON [dbo].[jobs_in_batch] TO [DDL_Viewer] AS [dbo]
GO
