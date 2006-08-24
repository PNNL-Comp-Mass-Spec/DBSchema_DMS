/****** Object:  UserDefinedFunction [dbo].[GetRequestedRunHistoryEUSUsersList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION GetRequestedRunHistoryEUSUsersList
/****************************************************
**
**	Desc: 
**  Builds delimited list of EUS users for
**  given requested run history
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/23/2006
**    
*****************************************************/
(
@requestID int,
@mode char(1) = 'I' -- 'N', 'V'
)
RETURNS varchar(1024)
AS
	BEGIN
		declare @list varchar(1024)
		set @list = ''

		IF @mode = 'I'
		BEGIN
			SELECT 
				@list = @list + CASE 
									WHEN @list = '' THEN CAST(EUS_Person_ID AS varchar(12))
									ELSE ', ' + CAST(EUS_Person_ID AS varchar(12))
								END
			FROM
			T_Requested_Run_History_EUS_Users INNER JOIN
			T_EUS_Users ON T_Requested_Run_History_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID	
			WHERE     (T_Requested_Run_History_EUS_Users.Request_ID = @requestID)	
		END	
		
		IF @mode = 'N'
		BEGIN
			SELECT 
				@list = @list + CASE 
									WHEN @list = '' THEN NAME_FM
									ELSE '; ' + NAME_FM
								END
			FROM
			T_Requested_Run_History_EUS_Users INNER JOIN
			T_EUS_Users ON T_Requested_Run_History_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID	
			WHERE     (T_Requested_Run_History_EUS_Users.Request_ID = @requestID)	
		END	
		
		IF @mode = 'V'
		BEGIN
			SELECT 
				@list = @list + CASE 
									WHEN @list = '' THEN NAME_FM + ' (' + CAST(EUS_Person_ID AS varchar(12)) + ' ' + T_EUS_Site_Status.ShortName + ')'
									ELSE '; ' + NAME_FM + ' (' + CAST(EUS_Person_ID AS varchar(12)) + ' ' + T_EUS_Site_Status.ShortName  + ')'
								END
			FROM
			T_Requested_Run_History_EUS_Users INNER JOIN
			T_EUS_Users ON T_Requested_Run_History_EUS_Users.EUS_Person_ID = T_EUS_Users.PERSON_ID INNER JOIN
                      T_EUS_Site_Status ON T_EUS_Users.Site_Status = T_EUS_Site_Status.ID	
			WHERE     (T_Requested_Run_History_EUS_Users.Request_ID = @requestID)	
			if @list = '' set @list = '(none)'
		END	
/**/		
		RETURN @list
	END

GO
