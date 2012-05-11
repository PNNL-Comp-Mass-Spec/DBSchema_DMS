/****** Object:  UserDefinedFunction [dbo].[GetExpAnnotationList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetExpAnnotationList
/****************************************************
**
**	Desc: 
**  Builds delimited list of annotations
**  given experiment
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 02/10/2010
**    
*****************************************************/
(
@experiment varchar(50)
)
RETURNS varchar(8000)
AS
	BEGIN
		declare @list varchar(1024)
		set @list = ''
		
		SELECT
		@list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + T_Experiment_Annotations.Key_Name + '='  + T_Experiment_Annotations.Value
		FROM
		  T_Experiment_Annotations
		  INNER JOIN T_Experiments ON T_Experiment_Annotations.Experiment_ID = T_Experiments.Exp_ID
		WHERE 
		  T_Experiments.Experiment_Num = @experiment
		ORDER BY 
			T_Experiment_Annotations.Key_Name

		RETURN @list
	END

GO
