/****** Object:  UserDefinedFunction [dbo].[GetAJProcessorGroupMembershipList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetAJProcessorGroupMembershipList
/****************************************************
**
**	Desc: 
**  Builds delimited list of analysis job processors
**  for given analysis job processor group ID
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 02/12/2007
**            02/20/2007 grk - Fixed reference to group ID
**    
*****************************************************/
(
@groupID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000)
		set @list = ''
		
		SELECT 
			@list = @list + CASE 
								WHEN @list = '' THEN Processor_Name + ' [' + Membership_Enabled + ']'
								ELSE ', ' + Processor_Name + ' [' + Membership_Enabled + ']'
							END
		FROM
			T_Analysis_Job_Processor_Group_Membership INNER JOIN
			T_Analysis_Job_Processors ON T_Analysis_Job_Processor_Group_Membership.Processor_ID = T_Analysis_Job_Processors.ID
		WHERE
			(T_Analysis_Job_Processor_Group_Membership.Group_ID = @groupID)
		RETURN @list
	END

GO
