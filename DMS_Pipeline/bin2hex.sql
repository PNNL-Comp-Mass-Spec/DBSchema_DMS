/****** Object:  UserDefinedFunction [dbo].[bin2hex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[bin2hex]
/****************************************************
**
**  Desc:
**    Convert Binary Data to Hexadecimal String
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  05/20/2008 -- initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**
*****************************************************/
(
 @binvalue varbinary(255)
)
RETURNS varchar(255)
AS
BEGIN
    -- The Transact-SQL CONVERT command converts binary data to
    -- character data in a one byte to one character fashion. SQL
    -- Server takes each byte of the source binary data, converts it to
    -- an integer value, then uses that integer value as the ASCII
    -- value for the destination character data. This behavior applies
    -- to the binary, varbinary, and timestamp datatypes.
    --
    -- For example, binary value 00001111 (0x0F in hexadecimal) is
    -- converted into its integer equivalent which is 15, then
    -- converted to the character that corresponds to ASCII value 15,
    -- which is unreadable.
    --
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
GRANT VIEW DEFINITION ON [dbo].[bin2hex] TO [DDL_Viewer] AS [dbo]
GO
