/****** Object:  UserDefinedFunction [dbo].[get_next_instrument_dataset_start] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_next_instrument_dataset_start]
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
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
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
GRANT VIEW DEFINITION ON [dbo].[get_next_instrument_dataset_start] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_next_instrument_dataset_start] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_next_instrument_dataset_start] TO [DMS2_SP_User] AS [dbo]
GO
