/****** Object:  StoredProcedure [dbo].[update_data_package_eus_info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_data_package_eus_info]
/****************************************************
**
**  Desc:
**      Updates EUS-related fields in T_Data_Package for one or more data packages
**      Also updates Instrument_ID
**
**  Auth:   mem
**  Date:   10/18/2016 mem - Initial version
**          10/19/2016 mem - Replace parameter @DataPackageID with @DataPackageList
**          11/04/2016 mem - Exclude proposals that start with EPR
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          07/07/2017 mem - Now updating Instrument and EUS_Instrument_ID
**          03/07/2018 mem - Properly handle null values for Best_EUS_Proposal_ID, Best_EUS_Instrument_ID, and Best_Instrument_Name
**          05/18/2022 mem - Use new EUS Proposal column name
**          06/08/2022 mem - Use new Item_Added column name
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          08/17/2023 mem - Use renamed column data_pkg_id in data package tables
**          09/26/2023 mem - Obtain dataset names and instrument names from T_Dataset and T_Instrument_Name
**
*****************************************************/
(
    @dataPackageList varchar(max),        -- '' or 0 to update all data packages, otherwise a comma separated list of data package IDs to update
    @message varchar(512)='' output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @DataPackageCount int = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'update_data_package_eus_info', @raiseError = 1
    If @authorized = 0
    Begin
        RAISERROR ('Access denied', 11, 3)
    End

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @DataPackageList = IsNull(@DataPackageList, '');
    Set @message = ''

    ---------------------------------------------------
    -- Populate a temporary table with the data package IDs to update
    ---------------------------------------------------

    CREATE TABLE dbo.[#TmpDataPackagesToUpdate] (
        ID int not NULL,
        Best_EUS_Proposal_ID varchar(10) NULL,
        Best_Instrument_Name varchar(50) NULL,
        Best_EUS_Instrument_ID int NULL
    )

    CREATE CLUSTERED INDEX [#IX_TmpDataPackagesToUpdate] ON [dbo].[#TmpDataPackagesToUpdate]
    (
        ID ASC
    )

    If @DataPackageList = '' Or @DataPackageList = '0' or @DataPackageList = ','
    Begin
        INSERT INTO #TmpDataPackagesToUpdate (ID)
        SELECT ID
        FROM T_Data_Package
    End
    Else
    Begin
        INSERT INTO #TmpDataPackagesToUpdate (ID)
        SELECT ID
        FROM T_Data_Package
        WHERE ID IN ( SELECT [Value]
                      FROM dbo.parse_delimited_integer_list ( @DataPackageList, ',' ) )
    End

    Set @myRowCount = 0
    SELECT @myRowCount = COUNT(*)
    FROM #TmpDataPackagesToUpdate

    Set @DataPackageCount = IsNull(@myRowCount, 0)

    If @DataPackageCount = 0
    Begin
        Set @message = 'No valid data packages were found in the list: ' + @DataPackageList
        Print @message
        Goto Done
    End
    Else
    Begin
        If @DataPackageCount > 1
        Begin
            Set @message = 'Updating ' + Cast(@DataPackageCount as varchar(12)) + ' data packages'
        End
        Else
        Begin
            Declare @firstID int

            SELECT @firstID = ID
            FROM #TmpDataPackagesToUpdate

            Set @message = 'Updating data package ' + Cast(@firstID as varchar(12))
        End

        -- Print @message
    End

    ---------------------------------------------------
    -- Update the EUS Person ID of the data package owner
    ---------------------------------------------------

    UPDATE T_Data_Package
    SET EUS_Person_ID = EUSUser.EUS_Person_ID
    FROM T_Data_Package DP
         INNER JOIN #TmpDataPackagesToUpdate Src
           ON DP.ID = Src.ID
         INNER JOIN S_DMS_V_EUS_User_ID_Lookup EUSUser
           ON DP.Owner = EUSUser.Username
    WHERE IsNull(DP.EUS_Person_ID, '') <> IsNull(EUSUser.EUS_Person_ID, '')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0 And @DataPackageCount > 1
    Begin
        Set @message = 'Updated EUS_Person_ID for ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' data package', ' data packages')
        Exec post_log_entry 'Normal', @message, 'update_data_package_eus_info'
    End


    ---------------------------------------------------
    -- Find the most common EUS proposal used by the datasets associated with each data package
    -- Exclude proposals that start with EPR since those are not official EUS proposals
    ---------------------------------------------------
    --
    UPDATE #TmpDataPackagesToUpdate
    SET Best_EUS_Proposal_ID = FilterQ.EUS_Proposal_ID
    FROM #TmpDataPackagesToUpdate Target
         INNER JOIN ( SELECT RankQ.Data_Pkg_ID,
                             RankQ.EUS_Proposal_ID
                      FROM ( SELECT Data_Pkg_ID,
                                    EUS_Proposal_ID,
                                    ProposalCount,
                                    Row_Number() OVER ( Partition By SourceQ.Data_Pkg_ID Order By ProposalCount DESC ) AS CountRank
                             FROM ( SELECT TD.Data_Pkg_ID,
                                           DR.Proposal AS EUS_Proposal_ID,
                                           COUNT(*) AS ProposalCount
                                    FROM T_Data_Package_Datasets TD
                                         INNER JOIN #TmpDataPackagesToUpdate Src
                                           ON TD.Data_Pkg_ID = Src.ID
                                         INNER JOIN S_V_Dataset_List_Report_2 DR
                                           ON TD.Dataset_ID = DR.ID
                                    WHERE NOT DR.Proposal IS NULL AND NOT DR.Proposal LIKE 'EPR%'
                                    GROUP BY TD.Data_Pkg_ID, DR.Proposal
                                  ) SourceQ
                           ) RankQ
                      WHERE RankQ.CountRank = 1
                     ) FilterQ
           ON Target.ID = FilterQ.Data_Pkg_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Look for any data packages that have a null Best_EUS_Proposal_ID in #TmpDataPackagesToUpdate
    -- yet have entries defined in T_Data_Package_EUS_Proposals
    ---------------------------------------------------
    --
    UPDATE #TmpDataPackagesToUpdate
    SET Best_EUS_Proposal_ID = FilterQ.Proposal_ID
    FROM #TmpDataPackagesToUpdate Target
         INNER JOIN ( SELECT Data_Pkg_ID,
                             Proposal_ID
                      FROM ( SELECT Data_Pkg_ID,
                                    Proposal_ID,
                                    Item_Added,
                                    Row_Number() OVER ( Partition By Data_Pkg_ID Order By Item_Added DESC ) AS IdRank
                             FROM T_Data_Package_EUS_Proposals
                             WHERE (Data_Pkg_ID IN ( SELECT ID
                                                     FROM #TmpDataPackagesToUpdate
                                                     WHERE Best_EUS_Proposal_ID IS NULL ))
                           ) RankQ
                      WHERE RankQ.IdRank = 1
                    ) FilterQ
           ON Target.ID = FilterQ.Data_Pkg_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Find the most common Instrument used by the datasets associated with each data package
    ---------------------------------------------------
    --
    UPDATE #TmpDataPackagesToUpdate
    SET Best_Instrument_Name = FilterQ.Instrument
    FROM #TmpDataPackagesToUpdate Target
         INNER JOIN ( SELECT RankQ.Data_Pkg_ID,
                             RankQ.Instrument
                      FROM ( SELECT Data_Pkg_ID,
                                    Instrument,
                                    InstrumentCount,
                                    Row_Number() OVER ( Partition By SourceQ.Data_Pkg_ID Order By InstrumentCount DESC ) AS CountRank
                             FROM ( SELECT TD.Data_Pkg_ID,
                                           InstName.IN_Name AS Instrument,
                                           COUNT(*) AS InstrumentCount
                                    FROM T_Data_Package_Datasets TD
                                         INNER JOIN S_Dataset DS
                                           ON TD.Dataset_ID = DS.Dataset_ID
                                         INNER JOIN S_Instrument_Name InstName
                                           ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                                         INNER JOIN #TmpDataPackagesToUpdate Src
                                           ON TD.Data_Pkg_ID = Src.ID
                                    WHERE NOT InstName.IN_Name Is Null
                                    GROUP BY TD.Data_Pkg_ID, InstName.IN_Name
                                  ) SourceQ
                           ) RankQ
                      WHERE RankQ.CountRank = 1
                     ) FilterQ
           ON Target.ID = FilterQ.Data_Pkg_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Update EUS_Instrument_ID in #TmpDataPackagesToUpdate
    ---------------------------------------------------
    --
    UPDATE #TmpDataPackagesToUpdate
    SET Best_EUS_Instrument_ID = EUSInst.EUS_Instrument_ID
    FROM #TmpDataPackagesToUpdate Target
         INNER JOIN S_V_EUS_Instrument_ID_Lookup EUSInst
           ON Target.Best_Instrument_Name = EUSInst.Instrument_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Update EUS Proposal ID, EUS_Instrument_ID, and Instrument_ID as necessary
    -- Do not change existing values in T_Data_Package to null values
    ---------------------------------------------------
    --
    UPDATE T_Data_Package
    SET EUS_Proposal_ID = Coalesce(Best_EUS_Proposal_ID, EUS_Proposal_ID),
        EUS_Instrument_ID = Coalesce(Best_EUS_Instrument_ID, EUS_Instrument_ID),
        Instrument = Coalesce(Best_Instrument_Name, Instrument)
    FROM T_Data_Package DP
         INNER JOIN #TmpDataPackagesToUpdate Src
           ON DP.ID = Src.ID
    WHERE IsNull(DP.EUS_Proposal_ID, '') <> Src.Best_EUS_Proposal_ID OR
          IsNull(DP.EUS_Instrument_ID, '') <> Src.Best_EUS_Instrument_ID OR
          IsNull(DP.Instrument, '') <> Src.Best_Instrument_Name
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount > 0 And @DataPackageCount > 1
    Begin
        Set @message = 'Updated EUS_Proposal_ID, EUS_Instrument_ID, and/or Instrument name for ' + Cast(@myRowCount as varchar(12)) + dbo.check_plural(@myRowCount, ' data package', ' data packages')
        Exec post_log_entry 'Normal', @message, 'update_data_package_eus_info'
    End

Done:

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_data_package_eus_info] TO [DDL_Viewer] AS [dbo]
GO
