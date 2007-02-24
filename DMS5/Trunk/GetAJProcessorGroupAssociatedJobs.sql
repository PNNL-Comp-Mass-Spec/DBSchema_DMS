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
**	Auth:	grk
**	Date:	02/16/2007
**			02/23/2007 mem - Added parameter @JobStateFilter
**    
*****************************************************/
(
	@groupID int,
	@JobStateFilter tinyint		-- 0 means new only, 1 means new and in progress only, anything else means all states
)
RETURNS varchar(64)
AS
	BEGIN
		declare @list varchar(64)
				
		set @JobStateFilter = IsNull(@JobStateFilter, 2)
		set @list = ''

		If @JobStateFilter = 0
		Begin
			SELECT @list = @list + ASN.AJS_name + ': ' + CAST(COUNT(AJPGA.Job_ID) AS varchar(12)) + ', '
			FROM T_Analysis_Job_Processor_Group_Associations AJPGA INNER JOIN
				T_Analysis_Job AJ ON AJPGA.Job_ID = AJ.AJ_jobID INNER JOIN
				T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID
			WHERE AJPGA.Group_ID = @groupID AND AJ.AJ_StateID IN (1, 8, 10)
			GROUP BY ASN.AJS_name, AJ.AJ_StateID
			ORDER BY AJ.AJ_StateID			
		End
		
		If @JobStateFilter = 1
		Begin
			SELECT @list = @list + ASN.AJS_name + ': ' + CAST(COUNT(AJPGA.Job_ID) AS varchar(12)) + ', '
			FROM T_Analysis_Job_Processor_Group_Associations AJPGA INNER JOIN
				T_Analysis_Job AJ ON AJPGA.Job_ID = AJ.AJ_jobID INNER JOIN
				T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID
			WHERE AJPGA.Group_ID = @groupID AND AJ.AJ_StateID IN (1, 2, 3, 8, 9, 10, 11, 16, 17)
			GROUP BY ASN.AJS_name, AJ.AJ_StateID
			ORDER BY AJ.AJ_StateID
		End
		
		If @JobStateFilter <> 0 And @JobStateFilter <> 1
		Begin
			SELECT @list = @list + ASN.AJS_name + ': ' + CAST(COUNT(AJPGA.Job_ID) AS varchar(12)) + ', '
			FROM T_Analysis_Job_Processor_Group_Associations AJPGA INNER JOIN
				T_Analysis_Job AJ ON AJPGA.Job_ID = AJ.AJ_jobID INNER JOIN
				T_Analysis_State_Name ASN ON AJ.AJ_StateID = ASN.AJS_stateID
			WHERE AJPGA.Group_ID = @groupID
			GROUP BY ASN.AJS_name, AJ.AJ_StateID
			ORDER BY AJ.AJ_StateID
		End
		
		If Len(@list) > 2
			Set @list = Left(@list, Len(@list)-1)

		RETURN convert(varchar(64), @list)
	END

GO
