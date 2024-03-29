/****** Object:  UserDefinedFunction [dbo].[get_multialign_data_from_item_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_multialign_data_from_item_list]
/****************************************************
**  Desc:
**
**  Return values:table of datasets for given list of jobs
**
**  Auth:   grk
**  Date:   02/05/2013 grk - initial release
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @sourceType VARCHAR(32), -- 'JobID, DatasetName, DataPackageID, DataPackageName
    @sourceList TEXT
)
RETURNS
@datasets TABLE (
    DatasetID INT,
    volName VARCHAR(128),
    path VARCHAR(255),
    datasetFolder VARCHAR(128),
    resultsFolder VARCHAR(128),
    datasetName VARCHAR(128),
    JobId INT,
    ColumnID INT,
    AcquisitionTime DATETIME,
    Labelling VARCHAR(64),
    InstrumentName VARCHAR(24),
    ToolID INT,
    BlockNum INT,
    ReplicateName VARCHAR(128),
    ExperimentID INT,
    RunOrder INT,
    BatchID INT,
    ArchPath VARCHAR(257),
    DatasetFullPath VARCHAR(511),
    Organism VARCHAR(128),
    Campaign VARCHAR(64),
    ParameterFileName VARCHAR(255),
    SettingsFileName VARCHAR(255)
)
AS
BEGIN
    DECLARE @items TABLE (
        Item VARCHAR(128)
    )
    INSERT INTO @items (Item)
    SELECT Item
    FROM dbo.make_table_from_list(@SourceList)

    IF(@SourceType = 'JobID')
    BEGIN
        INSERT INTO @datasets
        SELECT *
        FROM   V_Analysis_Job_Export_MultiAlign
        WHERE  JobId IN ( SELECT Item FROM @items )
    END

    IF(@SourceType = 'DatasetName')
    BEGIN
        INSERT INTO @datasets
        SELECT *
        FROM   V_Analysis_Job_Export_MultiAlign
        WHERE  datasetName IN ( SELECT Item FROM @items )
    END

    IF(@SourceType = 'DataPackageID')
    BEGIN
        INSERT INTO @datasets
        SELECT *
        FROM V_Analysis_Job_Export_MultiAlign
        WHERE JobId IN ( SELECT DISTINCT Job
                           FROM     dbo.S_V_Data_Package_Analysis_Jobs_Export
                           WHERE    Data_Package_ID IN ( SELECT Item FROM @items )
                        )
    END

    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_multialign_data_from_item_list] TO [DDL_Viewer] AS [dbo]
GO
