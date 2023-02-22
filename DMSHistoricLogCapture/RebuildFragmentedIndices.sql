/****** Object:  StoredProcedure [dbo].[RebuildFragmentedIndices] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[RebuildFragmentedIndices]
/****************************************************
**
**  Desc:
**      Temporary wrapper after renaming the procedure
**
*****************************************************/
(
    @maxFragmentation int = 25,
    @trivialPageCount int = 22,
    @verifyUpdateEnabled tinyint = 1,       -- When non-zero, then calls VerifyUpdateEnabled to assure that database updating is enabled
    @infoOnly tinyint = 1,
    @message varchar(1024) = '' output
)
AS
    Declare @myError int
    EXEC @myError = rebuild_fragmented_indices @maxFragmentation, @trivialPageCount, @verifyUpdateEnabled, @infoOnly, @message output
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RebuildFragmentedIndices] TO [DDL_Viewer] AS [dbo]
GO
