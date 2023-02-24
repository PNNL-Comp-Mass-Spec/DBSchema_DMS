/****** Object:  StoredProcedure [dbo].[ResolveStartAndEndDates] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[ResolveStartAndEndDates]
/****************************************************
** 
**  Desc:   Examines @startDate and @endDate to populate variables with actual Datetime values
**        
**  Return values: 0: success, otherwise, error code
** 
**  Date:   07/22/2019 mem - Initial version
**    
*****************************************************/
(
    @startDate varchar(24),
    @endDate varchar(24),
    @stDate datetime = Null output,
    @eDate datetime = Null output,
    @message varchar(512) = '' output
)
As
    Set nocount on
    
    Declare @eDateAlternate Datetime
    
    Set @message = ''

    --------------------------------------------------------------------
    -- If @endDate is empty, auto-set to the end of the current day
    --------------------------------------------------------------------
    --
    If IsNull(@endDate, '') = ''
    Begin
        Set @eDateAlternate = Convert(datetime, Convert(varchar(32), GETDATE(), 101))
        Set @eDateAlternate = DateAdd(second, 86399, @eDateAlternate)
        Set @eDateAlternate = DateAdd(millisecond, 995, @eDateAlternate)
        Set @endDate = Convert(varchar(32), @eDateAlternate, 121)
    End
    Else
    Begin
        If IsDate(@endDate) = 0
        Begin
            Set @message = 'End date "' + @endDate + '" is not a valid date'
            Return 56004
        End
    End
        
    --------------------------------------------------------------------
    -- Check whether @endDate only contains year, month, and day
    --------------------------------------------------------------------
    --
    set @eDate = Convert(DATETIME, @endDate, 102) 

    set @eDateAlternate = Convert(datetime, Floor(Convert(float, @eDate)))
    
    If @eDate = @eDateAlternate
    Begin
        -- @endDate only specified year, month, and day
        -- Update @eDateAlternate to span thru 23:59:59.997 on the given day,
        --  then copy that value to @eDate
        
        set @eDateAlternate = DateAdd(second, 86399, @eDateAlternate)
        set @eDateAlternate = DateAdd(millisecond, 995, @eDateAlternate)
        set @eDate = @eDateAlternate
    End
    
    --------------------------------------------------------------------
    -- If @startDate is empty, auto-set to 2 weeks before @eDate
    --------------------------------------------------------------------
    --
    If IsNull(@startDate, '') = ''
        Set @stDate = DateAdd(day, -14, Convert(datetime, Floor(Convert(float, @eDate))))
    Else
    Begin
        If IsDate(@startDate) = 0
        Begin
            set @message = 'Start date "' + @startDate + '" is not a valid date'
            Return 56005
        End

        Set @stDate = Convert(DATETIME, @startDate, 102) 
    End

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------
Done:
    return 0

GO
