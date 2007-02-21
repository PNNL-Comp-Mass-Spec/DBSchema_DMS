/****** Object:  UserDefinedFunction [dbo].[GetAJProcessorGroupAssociatedJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetAJProcessorGroupAssociatedJobs
/****************************************************
**
**	Desc: 
**  Gets jobs associated with given group
**
**	Return value: count
**
**	Parameters: 
**
**		Auth: grk
**		Date: 2/16/2007
**    
*****************************************************/
(
@groupID int
)
RETURNS varchar(64)
AS
	BEGIN
		declare @list varchar(64)
		set @list = ''

		SELECT  @list = @list + ' ' + T_Analysis_State_Name.AJS_name + ' (' + CAST(COUNT(T_Analysis_Job_Processor_Group_Associations.Job) AS varchar(12)) + ')'
		FROM         T_Analysis_Job_Processor_Group_Associations INNER JOIN
							T_Analysis_Job ON T_Analysis_Job_Processor_Group_Associations.Job = T_Analysis_Job.AJ_jobID INNER JOIN
							T_Analysis_State_Name ON T_Analysis_Job.AJ_StateID = T_Analysis_State_Name.AJS_stateID
		WHERE     (T_Analysis_Job_Processor_Group_Associations.[Group] = @groupID)
		GROUP BY T_Analysis_State_Name.AJS_name
		

		RETURN @list
	END

GO
