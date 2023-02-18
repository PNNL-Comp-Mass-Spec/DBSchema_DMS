/****** Object:  StoredProcedure [dbo].[RebuildFragmentedIndices] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[RebuildFragmentedIndices]
/****************************************************
**
**  Desc:
**      Reindexes fragmented indices in the database
**
**  Return values: 0:  success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   11/12/2007
**          10/15/2012 mem - Added spaces prior to printing debug messages
**          10/18/2012 mem - Added parameter @verify_update_enabled
**          07/16/2014 mem - Now showing table with detailed index info when @infoOnly = 1
**                         - Changed default value for @MaxFragmentation from 15 to 25
**                         - Changed default value for @TrivialPageCount from 12 to 22
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @MaxFragmentation int = 25,
    @TrivialPageCount int = 22,
    @VerifyUpdateEnabled tinyint = 1,       -- When non-zero, then calls verify_update_enabled to assure that database updating is enabled
    @infoOnly tinyint = 1,
    @message varchar(1024) = '' output
)
AS
    Declare @myError int
    Exec @myError = rebuild_fragmented_indices @MaxFragmentation, @TrivialPageCount, @VerifyUpdateEnabled, @infoOnly, @message
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RebuildFragmentedIndices] TO [DDL_Viewer] AS [dbo]
GO
