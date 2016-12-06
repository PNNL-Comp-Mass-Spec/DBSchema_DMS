/****** Object:  UserDefinedFunction [dbo].[GetExpGroupExperimentList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetExpGroupExperimentList
/****************************************************
**
**	Desc: 
**  Builds delimited list of experiments for
**  given Experiment Group
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 7/11/2006
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
								WHEN @list = '' THEN Experiment_Num
								ELSE ', ' + Experiment_Num
							END
		FROM 
			T_Experiments INNER JOIN
			T_Experiment_Group_Members ON T_Experiments.Exp_ID = T_Experiment_Group_Members.Exp_ID
		WHERE
			T_Experiment_Group_Members.Group_ID = @groupID
	
		RETURN @list
	END

GO
GRANT VIEW DEFINITION ON [dbo].[GetExpGroupExperimentList] TO [DDL_Viewer] AS [dbo]
GO
