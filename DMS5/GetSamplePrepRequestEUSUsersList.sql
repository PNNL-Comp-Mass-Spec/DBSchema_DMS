/****** Object:  UserDefinedFunction [dbo].[GetSamplePrepRequestEUSUsersList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetSamplePrepRequestEUSUsersList]
/****************************************************
**
**	Desc: 
**  Builds delimited list of EUS users for given sample prep request
**
**  @mode = 'I' means return integer
**  @mode = 'N' means return name
**  @mode = 'V' means return hybrid in the form Person_Name (Person_ID)
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: mem
**		Date: 05/01/2014
**    
*****************************************************/
(
@requestID int,
@mode char(1) = 'I' -- 'N', 'V'
)
RETURNS varchar(1024)
AS
Begin
	Declare @UserList varchar(1024)

	declare @list varchar(1024)
	set @list = ''

	SELECT @UserList = EUS_User_List
	FROM T_Sample_Prep_Request
	WHERE (ID = @requestID)

	If IsNull(@UserList, '') = ''
	Begin
		Set @list = '(none)'
	End
	Else
	Begin
		IF @mode = 'I'
		BEGIN
			SELECT 
				@list = @list + CASE 
									WHEN @list = '' THEN CAST(EU.Person_ID AS varchar(12))
									ELSE ', ' + CAST(EU.Person_ID AS varchar(12))
								END
			FROM ( SELECT Value AS Person_ID
			       FROM dbo.udfParseDelimitedList ( @UserList, ',' ) 
				 ) ReqUsers
			     INNER JOIN T_EUS_Users EU
			       ON ReqUsers.Person_ID = EU.PERSON_ID		
		END	
		
		IF @mode = 'N'
		BEGIN
			SELECT 
				@list = @list + CASE 
									WHEN @list = '' THEN EU.NAME_FM
									ELSE '; ' + EU.NAME_FM
								End
			FROM ( SELECT Value AS Person_ID
			       FROM dbo.udfParseDelimitedList ( @UserList, ',' ) 
				 ) ReqUsers
			     INNER JOIN T_EUS_Users EU
			       ON ReqUsers.Person_ID = EU.PERSON_ID			
		END	
		
		IF @mode = 'V'
		BEGIN
			SELECT 
				@list = @list + CASE 
									WHEN @list = '' THEN NAME_FM + ' (' + CAST(EU.PERSON_ID AS varchar(12)) + ')'
									ELSE '; ' + NAME_FM + ' (' + CAST(EU.PERSON_ID AS varchar(12)) + ')'
								End
			FROM ( SELECT Value AS Person_ID
			       FROM dbo.udfParseDelimitedList ( @UserList, ',' ) 
				 ) ReqUsers
			     INNER JOIN T_EUS_Users EU
			       ON ReqUsers.Person_ID = EU.PERSON_ID
		
			if @list = '' set @list = '(none)'
		END	
	End

	RETURN @list

END


GO
GRANT VIEW DEFINITION ON [dbo].[GetSamplePrepRequestEUSUsersList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetSamplePrepRequestEUSUsersList] TO [public] AS [dbo]
GO
