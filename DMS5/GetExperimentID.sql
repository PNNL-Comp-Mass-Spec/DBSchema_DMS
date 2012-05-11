/****** Object:  StoredProcedure [dbo].[GetExperimentID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetExperimentID
/****************************************************
**
**	Desc: Gets experiment ID for given experiment name
**
**	Return values: 0: failure, otherwise, experiment ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
(
	@experimentNum varchar(64) = " "
)
As
	declare @experimentID int
	set @experimentID = 0
	SELECT @experimentID = Exp_ID FROM T_Experiments WHERE (Experiment_Num = @experimentNum)
	return(@experimentID)
GO
GRANT EXECUTE ON [dbo].[GetExperimentID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetExperimentID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetExperimentID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetExperimentID] TO [PNL\D3M580] AS [dbo]
GO
