/****** Object:  UserDefinedFunction [dbo].[GetPrepLCExperimentGroupsList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetPrepLCExperimentGroupsList
/****************************************************
**
**	Desc: 
**  Builds delimited list of experiment groups
**  for given prep LC run
**
**	Return value: delimited list
**
**	Parameters: 
**
**		Auth: grk
**		Date: 04/30/2010
**    
*****************************************************/
(
@prepLCRunID int
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000)
		set @list = ''
		
		SELECT
		@list = @list + CASE WHEN @list = '' THEN CONVERT(VARCHAR(12), T_Experiment_Groups.Group_ID)
							 ELSE ', ' + CONVERT(VARCHAR(12), T_Experiment_Groups.Group_ID)
						END
		FROM
		T_Experiment_Groups
		INNER JOIN T_Prep_LC_Run ON T_Experiment_Groups.Prep_LC_Run_ID = T_Prep_LC_Run.ID
		WHERE
		T_Prep_LC_Run.ID = @prepLCRunID

		RETURN @list
	END

GO
GRANT VIEW DEFINITION ON [dbo].[GetPrepLCExperimentGroupsList] TO [DDL_Viewer] AS [dbo]
GO
