/****** Object:  StoredProcedure [dbo].[RebuildSparseIndices] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[RebuildSparseIndices]
/****************************************************
**
**	Temporary wrapper for renamed procedure
**    
*****************************************************/
(
	@fillFactorThreshold int = 90,
	@smallTableRowThreshold int = 1000,		-- Tables with fewer than this many rows will get a fill factor of 100 applied
	@newFillFactorLargeTables int = 90,		-- Fill_factor to use on tables with over @SmallTableRowThreshold rows
	@infoOnly tinyint = 1,
	@message varchar(1024) = '' output
)
AS
	Declare @myError int
    EXEC @myError = rebuild_sparse_indices @fillFactorThreshold, @smallTableRowThreshold, @newFillFactorLargeTables, @infoOnly, @message output
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RebuildSparseIndices] TO [DDL_Viewer] AS [dbo]
GO
