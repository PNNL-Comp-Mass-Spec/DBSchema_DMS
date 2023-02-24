/****** Object:  UserDefinedFunction [dbo].[GetNextInstrumentDatasetStart] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetNextInstrumentDatasetStart]
/****************************************************
**
**  Desc:
**  Returns start time of first dataset
**  that was run on given instrument after given time
**
**  Return value:
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/16/2011
**
*****************************************************/
(
    @instrumentID INT,
    @start datetime
)
RETURNS datetime
AS
    BEGIN
        declare @result datetime
        set @result = @start

        SELECT TOP(1) @result = Acq_Time_Start
        FROM    dbo.T_Dataset
        WHERE   DS_instrument_name_ID = @instrumentID
                AND Acq_Time_Start > @start
        ORDER BY Acq_Time_Start

        RETURN @result
    END
GO
GRANT VIEW DEFINITION ON [dbo].[GetNextInstrumentDatasetStart] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetNextInstrumentDatasetStart] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetNextInstrumentDatasetStart] TO [DMS2_SP_User] AS [dbo]
GO
