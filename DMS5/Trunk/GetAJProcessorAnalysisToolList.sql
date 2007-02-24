/****** Object:  UserDefinedFunction [dbo].[GetAJProcessorAnalysisToolList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetAJProcessorAnalysisToolList
/****************************************************
**
**	Desc: 
**  Builds delimited list of analysis tools
**  for given analysis job processor ID
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	02/23/2007 (Ticket 389)
**    
*****************************************************/
(
	@processorID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(64)
		set @list = ''
	
		SELECT @list = @list + T_Analysis_Tool.AJT_toolName + ', '
		FROM         T_Analysis_Job_Processor_Tools INNER JOIN
							T_Analysis_Tool ON T_Analysis_Job_Processor_Tools.Tool_ID = T_Analysis_Tool.AJT_toolID
		WHERE     (T_Analysis_Job_Processor_Tools.Processor_ID = @processorID)

		If Len(@list) > 2
			Set @list = Left(@list, Len(@list)-1)

		RETURN @list
	END

GO
