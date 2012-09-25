/****** Object:  UserDefinedFunction [dbo].[GetLongIntervalThreshold] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetLongIntervalThreshold
/****************************************************
**
**	Desc: 
**  Returns threshold value (in minutes) for interval
**  to be considered a long interval
**
**	Return values: 
**
**	Parameters:
**	
**	Auth: grk   
**		06/08/2012 grk - initial release
**    
*****************************************************/
()
RETURNS int
AS
	BEGIN
	RETURN 180
	END

GO
GRANT EXECUTE ON [dbo].[GetLongIntervalThreshold] TO [DMS2_SP_User] AS [dbo]
GO
