/****** Object:  UserDefinedFunction [dbo].[GetDateWithoutTime] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetDateWithoutTime]
/****************************************************
**
**	Desc: 
**		Rounds the date portion of @Date
**		Dates are truncated, not rounded
**
**	Auth:	mem
**	Date:	09/11/2012
**    
*****************************************************/
(
	@Date Datetime 
)
RETURNS Datetime
AS
BEGIN
	Declare @NewDate Datetime
	Set @NewDate = floor(convert(float, @Date))
	
	Return @NewDate
END

GO
