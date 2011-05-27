/****** Object:  UserDefinedFunction [dbo].[GetProposalEUSUsersList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetProposalEUSUsersList]
/****************************************************
**
**	Desc: Builds delimited list of EUS users for
**            given proposal
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	jds
**	Date:	09/07/2006
**			04/01/2011 mem - Added mode 'V' (verbose)
**						   - Now excluding users with State_ID 5="No longer associated with proposal"
**    
*****************************************************/
(
	@proposalID varchar(10),
	@mode char(1) = 'I'				-- Can be I, N, or V: I returns Person_ID values, N returns Names, V returns Name and Person_ID for each person
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
			        ELSE          ', ' + CAST(U.Person_ID AS varchar(12)) END
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END

	IF @mode = 'N'
	BEGIN
		set @list = ''

		SELECT 
			@list = @list + CASE 
			        WHEN @list = '' THEN NAME_FM 
			        ELSE          '; ' + NAME_FM END
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END

	IF @mode = 'V'
	BEGIN
		set @list = ''

		SELECT 
			@list = @list + CASE 
			WHEN @list = '' THEN NAME_FM + ' (' + CAST(U.Person_ID AS varchar(12)) + ')'
			ELSE          '; ' + NAME_FM + ' (' + CAST(U.Person_ID AS varchar(12)) + ')' END
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END

	RETURN @list
END



GO
GRANT EXECUTE ON [dbo].[GetProposalEUSUsersList] TO [DMS_User] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[GetProposalEUSUsersList] TO [DMS_User] AS [dbo]
GO
