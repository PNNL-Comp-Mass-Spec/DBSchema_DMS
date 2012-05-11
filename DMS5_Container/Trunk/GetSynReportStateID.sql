/****** Object:  StoredProcedure [dbo].[GetSynReportStateID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure GetSynReportStateID
/****************************************************
**
**	Desc: Gets sypnopsis Report state ID for given synopsis report
**
**	Return values: 0: failure, otherwise, synRepStateID
**
**	Parameters: 
**
**		Auth: jds
**		Date: 9/13/2004
**    
*****************************************************/
(
	@SynStateDescription varchar(255)
)
As
	declare @synRepStateID int
	set @synRepStateID = 0

	SELECT @synRepStateID = State_ID 
	FROM T_Peptide_Synopsis_Reports_State 
	WHERE (State_Description = @SynStateDescription)
	
	return(@synRepStateID)

GO
GRANT VIEW DEFINITION ON [dbo].[GetSynReportStateID] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSynReportStateID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSynReportStateID] TO [PNL\D3M580] AS [dbo]
GO
