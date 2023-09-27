/****** Object:  StoredProcedure [dbo].[refresh_data_package_items_using_dms] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[refresh_data_package_items_using_dms]
/****************************************************
**
**  Desc:
**      Updates metadata for items associated with the given data package
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**    Auth: grk
**    Date: 05/21/2009
**          06/10/2009 grk - Changed size of item list to max
**          03/07/2012 grk - Changed data type of @itemList from varchar(max) to text
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in data package tables
**
*****************************************************/
(
    @packageID int
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @message varchar(1024) = ''

    ---------------------------------------------------
    -- Update the experiment name associated with each dataset
    ---------------------------------------------------
    --
    UPDATE T_Data_Package_Datasets
    SET Experiment = E.Experiment_Num
    FROM T_Data_Package_Datasets Target INNER JOIN
        DMS5.dbo.T_Dataset DS ON Target.Dataset_ID = DS.Dataset_ID INNER JOIN
        DMS5.dbo.T_Experiments E ON DS.Exp_ID = E.Exp_ID AND Target.Experiment <> E.Experiment_Num
    WHERE Target.Data_Pkg_ID = @packageID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0
    Begin
        Set @message = 'Updated the experiment name for ' + Convert(varchar(12), @myRowCount) + ' datasets associated with data package ' + Convert(varchar(12), @packageID)

        Exec post_log_entry 'Info', @message, 'refresh_data_package_items_using_dms'
    End

    ---------------------------------------------------
    -- Update the campaign name associated with biomaterial (cell culture) entities
    ---------------------------------------------------
    --
    UPDATE T_Data_Package_Biomaterial
    SET Campaign = C.Campaign_Num
    FROM DMS5.dbo.T_Campaign C INNER JOIN
        DMS5.dbo.T_Cell_Culture CC ON C.Campaign_ID = CC.CC_Campaign_ID INNER JOIN
        T_Data_Package_Biomaterial Target ON CC.CC_ID = Target.Biomaterial_ID AND C.Campaign_Num <> Target.Campaign
    WHERE Target.Data_Pkg_ID = @packageID

    If @myRowCount > 0
    Begin
        Set @message = 'Updated the campaign name for ' + Convert(varchar(12), @myRowCount) + ' biomaterial entries associated with data package ' + Convert(varchar(12), @packageID)

        Exec post_log_entry 'Info', @message, 'refresh_data_package_items_using_dms'
    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[refresh_data_package_items_using_dms] TO [DDL_Viewer] AS [dbo]
GO
