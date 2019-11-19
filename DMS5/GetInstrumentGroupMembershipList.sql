/****** Object:  UserDefinedFunction [dbo].[GetInstrumentGroupMembershipList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetInstrumentGroupMembershipList]
/****************************************************
**
**  Desc: 
**      Builds delimited list of associated instruments
**      for given instrument group
**
**  Return value: delimited list
**
**  Auth:   grk
**  Date:   08/30/2010 grk - Initial version
**          11/18/2019 mem - Add parameters @activeOnly and @maximumLength
**    
*****************************************************/
(
    @instrumentGroup varchar(64),
    @activeOnly tinyint,             -- 0 for all instruments, 1 for only active instruments
    @maximumLength int = 64          -- Maximum length of the returned list of instruments; if 0, all instruments, sorted alphabetically; if non-zero, sort by descending instrument iD
)
RETURNS varchar(4000)
AS
    BEGIN
        Declare @list varchar(4000)
        
        Set @list = ''
        
        If @maximumLength <= 0
        Begin
            SELECT @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + IN_name     
            FROM   T_Instrument_Name
            WHERE  IN_Group = @InstrumentGroup And
                   (@activeOnly = 0 Or IN_status <> 'inactive') And
                   (@activeOnly = 0 Or IN_operations_role <> 'Offsite')
            ORDER BY IN_name ASC
        End
        Else
        Begin
            SELECT @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + IN_name     
            FROM   T_Instrument_Name
            WHERE  IN_Group = @InstrumentGroup And
                   (@activeOnly = 0 Or IN_status <> 'inactive') And
                   (@activeOnly = 0 Or IN_operations_role <> 'Offsite')
            ORDER BY IN_name ASC

            If Len(@list) > @maximumLength
            Begin
                Set @list = Rtrim(Substring(@list, 1, 61))
                If @list Like '%,'
                Begin
                    Set @list = Substring(@list, 1, Len(@list) - 1) + '...'
                End
                Else
                Begin
                    Set @list = @list + ' ...'
                End
            End
        End

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentGroupMembershipList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetInstrumentGroupMembershipList] TO [DMS2_SP_User] AS [dbo]
GO
