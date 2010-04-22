/****** Object:  StoredProcedure [dbo].[UpdateCellCultureTracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.UpdateCellCultureTracking
/****************************************************
**
**	Desc: Updates cell culture tracking table with summary counts
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**	
**
**	Auth:	grk
**	Date:	10/20/2002
**			11/15/2007 mem - Switched to Truncate Table for improved performance (Ticket:576)
**    
*****************************************************/
AS
	declare @message varchar(512)

	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	-- clear results table
	--
	TRUNCATE TABLE T_Cell_Culture_Tracking
	 
	-- make entry in results table for each cell culture
	--
	INSERT INTO T_Cell_Culture_Tracking
						(CC_ID)
	SELECT     CC_ID
	FROM         T_Cell_Culture
	 
	 
	-- update experiment count statistics for results table
	--
	UPDATE T
	SET Experiment_Count = S.Cnt
	FROM T_Cell_Culture_Tracking as T inner join
	(
	SELECT     CC_ID, COUNT(Exp_ID) AS Cnt
	FROM         T_Experiment_Cell_Cultures
	GROUP BY CC_ID
	) as S on T.CC_ID = S.CC_ID


	-- update dataset count statistics for results table
	--
	UPDATE T
	SET Dataset_Count = S.Cnt
	FROM T_Cell_Culture_Tracking as T inner join
	(
	SELECT     T_Experiment_Cell_Cultures.CC_ID, COUNT(T_Dataset.Dataset_ID) AS Cnt
	FROM         T_Experiment_Cell_Cultures INNER JOIN
						T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID INNER JOIN
						T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID
	GROUP BY T_Experiment_Cell_Cultures.CC_ID
	) as S on T.CC_ID = S.CC_ID 

	-- update analysis count statistics for results table
	--
	UPDATE T
	SET Job_Count = S.Cnt
	FROM T_Cell_Culture_Tracking as T inner join
	(
	SELECT     T_Experiment_Cell_Cultures.CC_ID, COUNT(T_Analysis_Job.AJ_jobID) AS Cnt
	FROM         T_Experiment_Cell_Cultures INNER JOIN
						T_Experiments ON T_Experiment_Cell_Cultures.Exp_ID = T_Experiments.Exp_ID INNER JOIN
						T_Dataset ON T_Experiments.Exp_ID = T_Dataset.Exp_ID INNER JOIN
						T_Analysis_Job ON T_Dataset.Dataset_ID = T_Analysis_Job.AJ_datasetID
	GROUP BY T_Experiment_Cell_Cultures.CC_ID
	) as S on T.CC_ID = S.CC_ID 

	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCellCultureTracking] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCellCultureTracking] TO [PNL\D3M580] AS [dbo]
GO
