/****** Object:  StoredProcedure [dbo].[update_protein_collection_usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_protein_collection_usage]
/****************************************************
**
**  Desc:   Updates the data in T_Protein_Collection_Usage
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   09/11/2012 mem - Initial version
**          11/20/2012 mem - Now updating Job_Usage_Count_Last12Months
**          08/14/2014 mem - Fixed bug updating Job_Usage_Count_Last12Months (occurred when a protein collection had not been used in the last year)
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Use tables T_Cached_Protein_Collection_List_Map and T_Cached_Protein_Collection_List_Members to minimize calls to make_table_from_list_delim
**          10/23/2017 mem - Use S_V_Protein_Collections_by_Organism instead of S_V_Protein_Collection_Picker since S_V_Protein_Collection_Picker only includes active protein collections
**          08/30/2018 mem - Tabs to spaces
**          07/27/2022 mem - Switch from FileName to Collection_Name when querying S_V_Protein_Collections_by_Organism
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(255) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    set @message = ''

    Declare @S varchar(max)

    Declare @CallingProcName varchar(128)
    Declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    ---------------------------------------------------
    -- Create the temporary table that will be used to
    -- track the number of inserts, updates, and deletes
    -- performed by the MERGE statement
    ---------------------------------------------------

    CREATE TABLE #Tmp_UpdateSummary (
        UpdateAction varchar(32)
    )

    Begin Try

        Set @CurrentLocation = 'Merge data into T_Protein_Collection_Usage'

        -- Use a MERGE Statement to synchronize T_Protein_Collection_Usage with S_V_Protein_Collections_by_Organism
        MERGE T_Protein_Collection_Usage AS target
        USING (SELECT DISTINCT Protein_Collection_ID AS ID, Collection_Name AS [Name]
               FROM S_V_Protein_Collections_by_Organism
            ) AS Source ( Protein_Collection_ID, [Name])
        ON (target.Protein_Collection_ID = source.Protein_Collection_ID)
        WHEN Matched AND ( Target.[Name] <> Source.[Name] ) THEN
            UPDATE Set
                  [Name] = Source.[Name]
        WHEN Not Matched THEN
            INSERT ( Protein_Collection_ID, [Name], Job_Usage_Count)
            VALUES ( Source.Protein_Collection_ID, Source.[Name], 0)
        WHEN NOT MATCHED BY SOURCE THEN
            DELETE
        OUTPUT $action INTO #Tmp_UpdateSummary
        ;
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            set @message = 'Error merging S_V_Protein_Collections_by_Organism with T_Protein_Collection_Usage (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute post_log_entry 'Error', @message, 'update_protein_collection_usage'
        End

        ---------------------------------------------------
        -- Update the usage counts in T_Protein_Collection_Usage
        -- We use tables T_Cached_Protein_Collection_List_Map and
        -- T_Cached_Protein_Collection_List_Members to
        -- minimize calls to make_table_from_list_delim
        ---------------------------------------------------

        -- First add any missing protein collection lists to T_Cached_Protein_Collection_List_Map
        --
        INSERT INTO T_Cached_Protein_Collection_List_Map( Protein_Collection_List )
        SELECT AJ_proteinCollectionList
        FROM T_Cached_Protein_Collection_List_Map Target
             RIGHT OUTER JOIN ( SELECT AJ_proteinCollectionList
                                FROM T_Analysis_Job
                                GROUP BY AJ_proteinCollectionList ) Source
               ON Target.Protein_Collection_List = Source.AJ_proteinCollectionList
        WHERE Target.Protein_Collection_List IS NULL
        ORDER BY AJ_proteinCollectionList
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Next add missing rows to T_Cached_Protein_Collection_List_Members
        --
        INSERT INTO T_Cached_Protein_Collection_List_Members( ProtCollectionList_ID,
                                                              Protein_Collection_Name )
        SELECT DISTINCT ProtCollectionList_ID,
                        ProteinCollections.Item
        FROM ( SELECT DISTINCT PCLMap.ProtCollectionList_ID,
                               PCLMap.Protein_Collection_List
               FROM T_Cached_Protein_Collection_List_Map PCLMap
                    LEFT OUTER JOIN T_Cached_Protein_Collection_List_Members PCLMembers
                      ON PCLMap.ProtCollectionList_ID = PCLMembers.ProtCollectionList_ID
               WHERE (PCLMembers.Protein_Collection_Name IS NULL)
             ) SourceQ
             CROSS APPLY dbo.make_table_from_list_delim ( SourceQ.Protein_Collection_List, ',' ) AS ProteinCollections
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Update the usage counts in T_Protein_Collection_Usage
        --
        UPDATE T_Protein_Collection_Usage
        SET Job_Usage_Count_Last12Months = UsageQ.Job_Usage_Count_Last12Months,
            Job_Usage_Count = UsageQ.Job_Usage_Count,
            Most_Recently_Used = UsageQ.Most_Recent_Date
        FROM T_Protein_Collection_Usage Target
             INNER JOIN ( SELECT PCLMembers.Protein_Collection_Name AS ProteinCollection,
                                 Sum(Jobs) AS Job_Usage_Count,
                                 Sum(Job_Usage_Count_Last12Months) AS Job_Usage_Count_Last12Months,
                                 Max(NewestJob) AS Most_Recent_Date
                          FROM ( SELECT AJ_proteinCollectionList,
                                        COUNT(*) AS Jobs,
                                        Sum(CASE WHEN COALESCE(AJ_created, AJ_start, AJ_finish) >= DateAdd(MONTH, - 12, GetDate())
                                                 THEN 1
                                                 ELSE 0
                                            END) AS Job_Usage_Count_Last12Months,
                                        MAX(COALESCE(AJ_created, AJ_start, AJ_finish)) AS NewestJob
                                 FROM T_Analysis_Job
                                 GROUP BY AJ_proteinCollectionList
                               ) CountQ
                               INNER JOIN T_Cached_Protein_Collection_List_Map PCLMap
                                 ON CountQ.AJ_proteinCollectionList = PCLMap.Protein_Collection_List
                               INNER JOIN T_Cached_Protein_Collection_List_Members PCLMembers
                                 ON PCLMap.ProtCollectionList_ID = PCLMembers.ProtCollectionList_ID
                          GROUP BY PCLMembers.Protein_Collection_Name
                        ) AS UsageQ
               ON Target.[Name] = UsageQ.ProteinCollection
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'update_protein_collection_usage')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_protein_collection_usage] TO [DDL_Viewer] AS [dbo]
GO
