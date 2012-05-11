/****** Object:  UserDefinedFunction [dbo].[bin2hex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[bin2hex] 
(
 @binvalue varbinary(255)
)
RETURNS varchar(255)
AS
BEGIN
	declare @charvalue varchar(255)
	declare @i int
	declare @length int
	declare @hexstring char(16)

	--select @charvalue = '0x'
	select @charvalue = ''
	select @i = 1
	select @length = datalength(@binvalue)
	--select @hexstring = '0123456789abcdef'
	select @hexstring = '0123456789ABCDEF'

	while (@i <= @length)
	begin
		declare @tempint int
		declare @firstint int
		declare @secondint int

		select @tempint = convert(int, substring(@binvalue,@i,1))
		select @firstint = floor(@tempint/16)
		select @secondint = @tempint - (@firstint*16)

		select @charvalue = @charvalue +
		substring(@hexstring, @firstint+1, 1) +
		substring(@hexstring, @secondint+1, 1)

		select @i = @i + 1
	end

	return @charvalue
END

GO
