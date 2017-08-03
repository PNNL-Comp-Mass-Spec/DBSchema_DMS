/****** Object:  StoredProcedure [dbo].[GetExperimentID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetExperimentID
/****************************************************
**
**	Desc: Gets experiment ID for given experiment name
**
**	Return values: 0: failure, otherwise, experiment ID
**
**	Auth:	grk
**	Date:	01/26/2001
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@experimentNum varchar(64) = " "
)
As
	Set NoCount On
	
	Declare @experimentID int = 0

	SELECT @experimentID = Exp_ID
	FROM T_Experiments
	WHERE Experiment_Num = @experimentNum
	
	return @experimentID
GO
GRANT VIEW DEFINITION ON [dbo].[GetExperimentID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetExperimentID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetExperimentID] TO [Limited_Table_Write] AS [dbo]
GO
