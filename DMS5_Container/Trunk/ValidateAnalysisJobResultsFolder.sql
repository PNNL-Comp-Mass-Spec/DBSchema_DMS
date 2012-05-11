/****** Object:  StoredProcedure [D3L243].[ValidateAnalysisJobResultsFolder] ******/
CREATE PROCEDURE [D3L243].[ValidateAnalysisJobResultsFolder]
	@Job [int],
	@JobCompleteHoldoffMinutes [int],
	@AnalysisManagerIsDone [tinyint] OUTPUT,
	@DataExtractionIsDone [tinyint] OUTPUT,
	@ResultsFolderName [nvarchar](4000) OUTPUT,
	@ResultsFolderPath [nvarchar](4000) OUTPUT,
	@ResultsFolderTimestamp [datetime] OUTPUT,
	@OrganismDBName [nvarchar](4000) OUTPUT,
	@Message [nvarchar](4000) OUTPUT,
	@InfoOnly [tinyint] OUTPUT
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [AnalysisJobResultFolderValidation].[AnalysisJobResultFolderValidation.StoredProcedures].[ValidateAnalysisJobResultsFolder]
GO
