/****** Object:  UserDefinedFunction [dbo].[GetProposalEUSUsersList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION GetProposalEUSUsersList
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
**			06/13/2013 mem - Added mode 'L' (last names only)
**    
*****************************************************/
(
	@proposalID varchar(10),
	@mode char(1) = 'I'				-- Can be I, N, L, or V: I returns Person_ID values, N returns Names, L returns Last name Only, V returns Name and Person_ID for each person
)
RETURNS varchar(1024)
AS
	BEGIN

	declare @list varchar(4096)
	IF @mode = 'I'
	BEGIN
		set @list = null

		SELECT 
			@list = COALESCE(@list + ', ', '') + CAST(U.Person_ID AS varchar(12))
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END

	IF @mode = 'N'
	BEGIN
		set @list = null

		SELECT 
			@list = COALESCE(@list + '; ', '') + NAME_FM
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END


	IF @mode = 'L'
	BEGIN
		set @list = null

		SELECT 
			@list = COALESCE(@list + '; ', '') + Last_Name
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END
	
	IF @mode = 'V'
	BEGIN
		set @list = null

		SELECT 
			@list = COALESCE(@list + '; ', '') + NAME_FM + ' (' + CAST(U.Person_ID AS varchar(12)) + ')'		
		FROM
			T_EUS_Proposal_Users P INNER JOIN
			T_EUS_Users U ON P.Person_ID = U.PERSON_ID	
		WHERE P.Proposal_ID = @proposalID AND 
		      P.State_ID <> 5
	
	END

	RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[GetProposalEUSUsersList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetProposalEUSUsersList] TO [DMS_User] AS [dbo]
GO
GRANT REFERENCES ON [dbo].[GetProposalEUSUsersList] TO [DMS_User] AS [dbo]
GO
