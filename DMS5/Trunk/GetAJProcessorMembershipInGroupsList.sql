/****** Object:  UserDefinedFunction [dbo].[GetAJProcessorMembershipInGroupsList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetAJProcessorMembershipInGroupsList
/****************************************************
**
**	Desc: 
**  Builds delimited list of processor group IDs
**  for given analysis job processor ID
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
@processorID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000)
		set @list = ''
		
		SELECT 
			@list = @list + CASE 
								WHEN @list = '' THEN Group_Name + ' (' + CAST(ID as Varchar(12)) + ')' + ' [' + Membership_Enabled + ']'
								ELSE ', ' + Group_Name + ' (' + CAST(ID as Varchar(12)) + ')' +  ' [' + Membership_Enabled + ']'
							END
		FROM
			T_Analysis_Job_Processor_Group_Membership INNER JOIN
			T_Analysis_Job_Processor_Group ON 
			T_Analysis_Job_Processor_Group_Membership.Group_ID = T_Analysis_Job_Processor_Group.ID
		WHERE
			(T_Analysis_Job_Processor_Group_Membership.Processor_ID = @processorID)
	
		RETURN @list
	END

GO
