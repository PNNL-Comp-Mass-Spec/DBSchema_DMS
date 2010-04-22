/****** Object:  UserDefinedFunction [dbo].[GetEUSUsersProposalList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetEUSUsersProposalList
/****************************************************
**
**	Desc: Builds delimited list of proposals for
**            given EUS user
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 12/28/2008
**    
*****************************************************/
(
@personID varchar(10)
)
RETURNS varchar(1024)
AS
	BEGIN

	declare @list varchar(4096)
	set @list = ''

	SELECT 
		@list = @list + CASE 
		WHEN @list = '' THEN CAST(P.Proposal_ID AS varchar(12))
		ELSE ', ' + CAST(P.Proposal_ID AS varchar(12)) END
	FROM
		T_EUS_Proposal_Users P 
	WHERE     (Person_ID = @personID)	
		

	RETURN @list
	END

GO
