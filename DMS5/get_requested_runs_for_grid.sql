/****** Object:  StoredProcedure [dbo].[get_requested_runs_for_grid] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[get_requested_runs_for_grid]
/****************************************************
**
**  Desc:
**      Returns the info for the requested run IDs in @itemList
**
**  Auth:   grk
**  Date:   01/13/2013
**          01/13/2013 grk - Initial release
**          03/14/2013 grk - Removed "Active" status filter
**          10/19/2020 mem - Rename the instrument group column to RDS_instrument_group
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          10/10/2023 mem - Rename column instrument to instrument_group
**                         - Rename column separation_type to separation_group
**
*****************************************************/
(
    @itemList text,
    @message varchar(512)='' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    -----------------------------------------
    -- convert item list into temp table
    -----------------------------------------
    --
    CREATE TABLE #ITEMS (
        Item varchar(128)
    )

    INSERT INTO #ITEMS (Item)
    SELECT Item
    FROM dbo.make_table_from_list(@itemList)

    -----------------------------------------
    -- Return results
    -----------------------------------------

    SELECT TRR.ID AS Request,
           TRR.RDS_Name AS Name,
           TRR.RDS_Status AS Status,
           TRR.RDS_BatchID AS BatchID,
           TRR.RDS_instrument_group AS Instrument_Group,
           TRR.RDS_Sec_Sep AS Separation_Group,
           TEX.Experiment_Num AS Experiment,
           T_LC_Cart.Cart_Name AS Cart,
           TRR.RDS_Cart_Col AS [Column],
           TRR.RDS_Block AS Block,
           TRR.RDS_Run_Order AS Run_Order
    FROM T_Requested_Run TRR
         INNER JOIN T_LC_Cart
           ON TRR.RDS_Cart_ID = T_LC_Cart.ID
         INNER JOIN T_Requested_Run_Batches TRB
           ON TRR.RDS_BatchID = TRB.ID
         INNER JOIN T_Experiments TEX
           ON TRR.Exp_ID = TEX.Exp_ID
    WHERE TRR.ID IN ( SELECT Item FROM #ITEMS )

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[get_requested_runs_for_grid] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_requested_runs_for_grid] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_requested_runs_for_grid] TO [DMS2_SP_User] AS [dbo]
GO
