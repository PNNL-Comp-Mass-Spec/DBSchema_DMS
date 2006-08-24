/****** Object:  UserDefinedFunction [dbo].[CreateLikeClauseFromSeparatedString] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION CreateLikeClauseFromSeparatedString
/****************************************************
**
**	Desc: Parses the text in @inString, looking for @separator
**		  and generating a valid Sql Like clause for field @separator
**
**	Returns the Sql Like clause
**
**		Auth:	jds
**		Date:	12/16/2004
**				07/26/2005 mem - Now trimming white space from beginning and end of text extracted from @inString
**							   - Increased size of return variable from 2048 to 4096 characters
*****************************************************/
(
	@inString varchar(2048), 
	@fieldName varchar(50), 
	@separator varchar(1)
)
	RETURNS varchar(4096)
AS
begin
  declare @pos1 int
  declare @retString varchar(2048)
  declare @i int

  set @inString = replace(@inString, '_', '[_]')
  set @retString = ' '
  set @i = 1
  WHILE len(@inString) > 0
    BEGIN
      set @pos1 = charindex(@separator, @inString)
      if @pos1 > 0
        begin
          if @i = 1 
            Set @retString = '((' + @fieldName + ' like ''' + LTrim(RTrim(substring(@inString, 1, @pos1 - 1))) + ''')'
          else
            Set @retString = @retString + ' OR ' + '(' + @fieldName + ' like ''' + LTrim(RTrim(substring(@inString, 1, @pos1 - 1))) + ''')'
          Set @i = @i + 1
          Set @inString = substring(@inString, @pos1 + 1, len(@inString) -1)
          continue
        end
      else
        begin
          if @i = 1
            Set @retString = '((' + @fieldName + ' like ''' + LTrim(RTrim(@inString)) + '''))'
          else
            Set @retString = @retString + ' OR ' + '(' + @fieldName + ' like ''' + LTrim(RTrim(@inString)) + '''))'
          break
        end
    END

  set @retString = rtrim(@retString) 
  return(@retString)
end

GO
