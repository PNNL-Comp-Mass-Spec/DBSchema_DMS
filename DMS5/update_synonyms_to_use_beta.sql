/****** Object:  StoredProcedure [dbo].[update_synonyms_to_use_beta] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_synonyms_to_use_beta]
/****************************************************
**
**  Desc:
**      Updates DMS_Data_Package synonyms to use [DMS_Data_Package_Beta]
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   04/30/2015 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(128)='' output
)
AS
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    ---------------------------------------------------
    -- Populate a temorary table with the requests to process
    ---------------------------------------------------

    Declare @ThisDB varchar(64) = Db_Name()

    If @ThisDB <> 'DMS5_Beta'
    Begin
        Set @message = 'This stored procedure can only be run from the DMS5_Beta database'
        print @message
        Goto Done
    End

    ---------------------------------------------------
    -- Drop existing DMS_Data_Package synonyms
    ---------------------------------------------------

    PRINT 'Dropping DMS_Data_Package synonyms'
    DROP SYNONYM [dbo].[S_V_Data_Package_Analysis_Jobs_Export]
    DROP SYNONYM [dbo].[S_V_Data_Package_Datasets_Export]
    DROP SYNONYM [dbo].[S_V_Data_Package_Experiments_Export]
    DROP SYNONYM [dbo].[S_V_Data_Package_Export]
    DROP SYNONYM [dbo].[S_V_OSM_Package_Export]

    ---------------------------------------------------
    --Create new DMS_Data_Package synonyms
    ---------------------------------------------------

    PRINT 'Creating synonyms using [DMS_Data_Package_Beta]'
    CREATE SYNONYM [dbo].[S_V_Data_Package_Analysis_Jobs_Export] FOR [DMS_Data_Package_Beta].[dbo].[V_Data_Package_Analysis_Jobs_Export]
    CREATE SYNONYM [dbo].[S_V_Data_Package_Datasets_Export] FOR [DMS_Data_Package_Beta].[dbo].[V_Data_Package_Dataset_Export]
    CREATE SYNONYM [dbo].[S_V_Data_Package_Experiments_Export] FOR [DMS_Data_Package_Beta].[dbo].[V_Data_Package_Experiments_Export]
    CREATE SYNONYM [dbo].[S_V_Data_Package_Export] FOR [DMS_Data_Package_Beta].[dbo].[V_Data_Package_Export]
    CREATE SYNONYM [dbo].[S_V_OSM_Package_Export] FOR [DMS_Data_Package_Beta].[dbo].[T_OSM_Package]

    Set @message = 'Updated synonyms to use database DMS_Data_Package_Beta'

Done:
    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[update_synonyms_to_use_beta] TO [DDL_Viewer] AS [dbo]
GO
