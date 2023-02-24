/****** Object:  UserDefinedFunction [dbo].[GetExpRefCompoundList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.GetExpRefCompoundList
/****************************************************
**
**	Desc: 
**  Builds delimited list of reference compounds for given experiment
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	11/29/2017
**			01/04/2018 mem - Now caching reference compounds using the ID_Name field (which is of the form Compound_ID:Compound_Name)
**    
*****************************************************/
(
	@experimentNum varchar(50)
)
RETURNS varchar(2048)
AS
BEGIN
	Declare @list varchar(2048) = null
	
	SELECT @list = Coalesce(@list + '; ' + RC.ID_Name, RC.ID_Name)
	FROM T_Experiment_Reference_Compounds ERC
	     INNER JOIN T_Experiments E
	       ON ERC.Exp_ID = E.Exp_ID
	     INNER JOIN T_Reference_Compound RC
	       ON ERC.Compound_ID = RC.Compound_ID
	WHERE E.Experiment_Num = @experimentNum
	
	If @list Is Null
		Set @list = ''

	RETURN @list
END


GO
