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
**			03/15/2007 mem - Increased size of @list to varchar(4000); now ordering by tool name
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
	
		SELECT @list = @list + T.AJT_toolName + ', '
		FROM T_Analysis_Job_Processor_Tools AJPT INNER JOIN
			 T_Analysis_Tool T ON AJPT.Tool_ID = T.AJT_toolID
		WHERE (AJPT.Processor_ID = @processorID)
		ORDER BY T.AJT_toolName

		If Len(@list) > 2
			Set @list = Left(@list, Len(@list)-1)

		RETURN @list
	END


GO
