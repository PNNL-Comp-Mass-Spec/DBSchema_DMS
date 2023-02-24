/****** Object:  StoredProcedure [dbo].[GetNewJobID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetNewJobID]
/****************************************************
**
**  Desc:
**    Gets a unique number for making a new job
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   08/04/2009
**          08/05/2009 grk - initial release (Ticket #744, http://prismtrac.pnl.gov/trac/ticket/744)
**          08/05/2009 mem - Now using SCOPE_IDENTITY() to determine the ID of the newly added row
**          06/24/2015 mem - Added parameter @infoOnly
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @note varchar(266),
    @infoOnly tinyint = 0
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    declare @id int = 0

    If IsNull(@infoOnly, 0) <> 0
    Begin
        -- Preview the next job number
        SELECT @id = MAX(ID) + 1
        FROM T_Analysis_Job_ID
    End
    Else
    Begin
        -- Insert new row in job ID table to create unique ID
        --
        INSERT INTO T_Analysis_Job_ID (
            Note
        ) VALUES (
            @Note
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError = 0
        Begin
            -- get ID of newly created entry
            --
            set @id = SCOPE_IDENTITY()
        End
    End

    return @id

GO
GRANT VIEW DEFINITION ON [dbo].[GetNewJobID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetNewJobID] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetNewJobID] TO [Limited_Table_Write] AS [dbo]
GO
