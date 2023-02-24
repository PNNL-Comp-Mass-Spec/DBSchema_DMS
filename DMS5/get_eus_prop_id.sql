/****** Object:  StoredProcedure [dbo].[GetEUSPropID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetEUSPropID
/****************************************************
**
**	Desc: Gets EUS Proposal ID for given EUS Proposal ID
**
**	Return values: 0: failure, otherwise, Proposal ID
**
**	Auth:	jds
**	Date:	09/01/2006
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@EUSPropID varchar(10) = " "
)
As
	Set NoCount On
	
	Declare @tempEUSPropID varchar(10) = '0'

	SELECT @tempEUSPropID = PROPOSAL_ID
	FROM T_EUS_Proposals
	WHERE PROPOSAL_ID = @EUSPropID

	return @tempEUSPropID



GO
GRANT VIEW DEFINITION ON [dbo].[GetEUSPropID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetEUSPropID] TO [Limited_Table_Write] AS [dbo]
GO
