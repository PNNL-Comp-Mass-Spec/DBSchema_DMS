/****** Object:  UserDefinedFunction [dbo].[get_active_instrument_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_active_instrument_id]
/****************************************************
**
**  Desc: Gets the "Active" InstrumentID for given instrument name
**
**  Return values: 0: failure, otherwise, instrument ID
**
**  Parameters: Instrument Name - the name of the instrument
**
**  Auth:   jds
**  Date:   06/28/2004
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrumentName varchar(80) = " "
)
RETURNS int
AS
BEGIN
    Declare @instrumentID int = 0

    SELECT @instrumentID = Instrument_ID
    FROM T_Instrument_Name
         INNER JOIN T_Archive_Path
           ON Instrument_ID = AP_Instrument_Name_ID AND
              IN_name = @instrumentName AND
              AP_Function = 'Active'

    return @instrumentID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_active_instrument_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_active_instrument_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_active_instrument_id] TO [Limited_Table_Write] AS [dbo]
GO
