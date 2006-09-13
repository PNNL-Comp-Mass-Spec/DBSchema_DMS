/****** Object:  StoredProcedure [dbo].[GetEUSPropID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure dbo.GetEUSPropID
/****************************************************
**
**	Desc: Gets EUS Proposal ID for given EUS Proposal ID
**
**	Return values: 0: failure, otherwise, Proposal ID
**
**	Parameters: 
**
**		Auth: jds
**		Date: 9/1/2006
**    
*****************************************************/
(
	@EUSPropID varchar(10) = " "
)
As
	declare @tempEUSPropID varchar(10)

	set @tempEUSPropID = '0'
	SELECT @tempEUSPropID = PROPOSAL_ID 
	FROM T_EUS_Proposals WHERE (PROPOSAL_ID = @EUSPropID)

	return(@tempEUSPropID)



GO
