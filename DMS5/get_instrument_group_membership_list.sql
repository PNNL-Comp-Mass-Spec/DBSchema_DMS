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
**          02/18/2021 mem - Add @activeOnly=2 which formats the instruments as a vertical bar separated list of instrument name and instrument ID
**    
*****************************************************/
(
    @instrumentGroup varchar(64),
    @activeOnly tinyint,             -- 0 for all instruments, 1 for only active instruments, 2 to format the instruments as a vertical bar separated list of instrument name and ID (see comments below)
    @maximumLength int = 64          -- Maximum length of the returned list of instruments; if 0, all instruments, sorted alphabetically; if non-zero, sort by descending instrument ID
)
RETURNS varchar(4000)
AS
    BEGIN
        Declare @list varchar(4000) = ''
        
        -- When @activeOnly is 2, the instrument list will be in the form:
        -- InstrumentName:InstrumentID|InstrumentName:InstrumentID|InstrumentName:InstrumentID
        -- Additionally, if the instrument is inactive of offsite, the instrument name will show that in parentheses, with inactive taking precedence
        -- This is used to format instrument on the Instrument Group Detail Report page
        -- https://dms2.pnl.gov/instrument_group/show/VelosOrbi

        Declare @delimiter VARCHAR(4)

        If @activeOnly = 2
        Begin
            Set @delimiter = '|'
        End
        Else
        Begin
            Set @delimiter  = ', '
        End

        If @maximumLength > 0 And @maximumLength < 10
        Begin
            Set @maximumLength = 10
        End

        SELECT @list = @list + CASE WHEN @list = '' THEN '' ELSE @delimiter END + 
                       IN_name + 
                       CASE When @activeOnly = 2 AND IN_Status = 'inactive' THEN ' (' + IN_status + ')' ELSE '' END +
                       CASE When @activeOnly = 2 AND IN_Status <> 'inactive' AND IN_operations_role = 'Offsite' THEN ' (' + IN_operations_role + ')' ELSE '' END +
                       CASE When @activeOnly = 2 THEN ':' + CAST(Instrument_ID as VARCHAR(12)) ELSE '' END
        FROM   T_Instrument_Name
        WHERE  IN_Group = @InstrumentGroup And
                (@activeOnly In (0, 2) Or IN_status <> 'inactive') And
                (@activeOnly In (0, 2) Or IN_operations_role <> 'Offsite')
        ORDER BY IN_name ASC

        If @maximumLength > 0 And Len(@list) > @maximumLength
        Begin
            Set @list = Rtrim(Substring(@list, 1, @maximumLength - 3))

            If @list Like '%,'
            Begin
                Set @list = Substring(@list, 1, Len(@list) - 1) + '...'
            End
            Else
            Begin
                Set @list = @list + ' ...'
            End
        End

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentGroupMembershipList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetInstrumentGroupMembershipList] TO [DMS2_SP_User] AS [dbo]
GO
