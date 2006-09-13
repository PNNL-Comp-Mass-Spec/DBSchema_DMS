/****** Object:  UserDefinedFunction [dbo].[GetProposalEUSUsersList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetProposalEUSUsersList
/****************************************************
**
**	Desc: Builds delimited list of EUS users for
**            given proposal
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: jds
**		Date: 9/7/2006
**    
*****************************************************/
(
@proposalID varchar(10),
@mode char(1) = 'I' -- 'N'
)
RETURNS varchar(1024)
AS
	BEGIN

	declare @list varchar(4096)
	IF @mode = 'I'
		BEGIN
			set @list = ''

			SELECT 
				@list = @list + CASE 
				WHEN @list = '' THEN CAST(U.Person_ID AS varchar(12))
				ELSE ', ' + CAST(U.Person_ID AS varchar(12)) END
			FROM
				T_EUS_Proposal_Users P INNER JOIN
				T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
			WHERE     (P.Proposal_ID = @proposalID)	
		
		END

	IF @mode = 'N'
		BEGIN
			set @list = ''

			SELECT 
				@list = @list + CASE 
				WHEN @list = '' THEN NAME_FM 
				ELSE '; ' + NAME_FM END
			FROM
				T_EUS_Proposal_Users P INNER JOIN
				T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
			WHERE     (P.Proposal_ID = @proposalID)	
		
		END

		RETURN @list
	END


GO
