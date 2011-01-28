/****** Object:  StoredProcedure [dbo].[GetAnalysisStateID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE GetAnalysisStateID
/****************************************************
**
**	Desc: Gets Analysis Job state ID for given state name
**
**	Return values: 0: failure, otherwise, instrument ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 71/17/2005
**    
*****************************************************/
(
	@analysisJobStateName varchar(32) = " "
)
As
	declare @stateID int
	set @stateID = 0
	SELECT @stateID = AJS_stateID FROM T_Analysis_State_Name WHERE (AJS_name = @analysisJobStateName)
	return @stateID

GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisStateID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisStateID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetAnalysisStateID] TO [PNL\D3M580] AS [dbo]
GO
