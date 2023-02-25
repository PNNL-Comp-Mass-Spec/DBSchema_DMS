/****** Object:  StoredProcedure [dbo].[clear_all_data] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE clear_all_data
/****************************************************
**
**  Desc:
**      This is a DANGEROUS procedure that will clear all
**      data from all of the tables in this database
**
**      This is useful for creating test databases
**      or for migrating the DMS databases to a new laboratory
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   08/20/2015 mem - Initial release
**
*****************************************************/
(
    @ServerNameFailsafe varchar(64) = 'Pass in the name of the current server to confirm that you truly want to delete data',
    @CurrentDateFailsafe varchar(64) = 'Enter the current date, in the format yyyy-mm-dd',
    @infoOnly tinyint = 1,
    @message varchar(255) = '' output
)
As
    Set NoCount On

    declare @myRowCount int
    declare @myError int
    set @myRowCount = 0
    set @myError = 0

    set @infoOnly = IsNull(@infoOnly, 1)
    set @message = ''

    -------------------------------------------------
    -- Verify that we truly should do this
    -------------------------------------------------

    If @ServerNameFailsafe <> @@ServerName
    Begin
        set @message = 'You must enter the name of the server hosting this database'
        Goto Done
    End

    Declare @userDate date
    set @userDate = Convert(date, @CurrentDateFailsafe)

    If IsNull(@userDate, '') = '' OR @userDate <> Cast(GetDate() as Date)
    Begin
        set @message = 'You must set @CurrentDateFailsafe to the current date, in the form yyyy-mm-dd'
        Goto Done
    End

    -------------------------------------------------
    -- Remove foreign keys
    -------------------------------------------------

    If @infoOnly = 0
    Begin

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Data_Package_EUS_Proposals_T_Data_Package')
          ALTER TABLE dbo.T_Data_Package_EUS_Proposals
            DROP CONSTRAINT FK_T_Data_Package_EUS_Proposals_T_Data_Package

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Data_Package_Experiments_T_Data_Package')
          ALTER TABLE dbo.T_Data_Package_Experiments
            DROP CONSTRAINT FK_T_Data_Package_Experiments_T_Data_Package

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Data_Package_Datasets_T_Data_Package')
          ALTER TABLE dbo.T_Data_Package_Datasets
            DROP CONSTRAINT FK_T_Data_Package_Datasets_T_Data_Package

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Data_Package_Biomaterial_T_Data_Package')
          ALTER TABLE dbo.T_Data_Package_Biomaterial
            DROP CONSTRAINT FK_T_Data_Package_Biomaterial_T_Data_Package

        IF EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_T_Data_Package_Analysis_Jobs_T_Data_Package')
          ALTER TABLE dbo.T_Data_Package_Analysis_Jobs
            DROP CONSTRAINT FK_T_Data_Package_Analysis_Jobs_T_Data_Package

    End

    -------------------------------------------------
    -- Truncate tables
    -------------------------------------------------

    If @infoOnly = 0
    Begin
        Select 'Deleting data' AS Task

        TRUNCATE TABLE T_Data_Package
        TRUNCATE TABLE T_Data_Package_Analysis_Jobs
        TRUNCATE TABLE T_Data_Package_Biomaterial
        TRUNCATE TABLE T_Data_Package_Datasets
        TRUNCATE TABLE T_Data_Package_EUS_Proposals
        TRUNCATE TABLE T_Data_Package_Experiments
        TRUNCATE TABLE T_Log_Entries
        TRUNCATE TABLE T_MyEMSL_Uploads
        TRUNCATE TABLE T_OSM_Package

        Select 'Deletion Complete' AS Task
    End
    Else
    Begin

        SELECT 'T_Data_Package'
        UNION
        SELECT 'T_Data_Package_Analysis_Jobs'
        UNION
        SELECT 'T_Data_Package_Biomaterial'
        UNION
        SELECT 'T_Data_Package_Datasets'
        UNION
        SELECT 'T_Data_Package_EUS_Proposals'
        UNION
        SELECT 'T_Data_Package_Experiments'
        UNION
        SELECT 'T_Log_Entries'
        UNION
        SELECT 'T_MyEMSL_Uploads'
        UNION
        SELECT 'T_OSM_Package'
        ORDER BY 1

    End

    -------------------------------------------------
    -- Add back foreign keys
    -------------------------------------------------

    If @infoOnly = 0
    Begin

        alter table T_Data_Package_Analysis_Jobs add
            constraint FK_T_Data_Package_Analysis_Jobs_T_Data_Package foreign key(Data_Package_ID) references T_Data_Package(ID) on delete cascade;

        alter table T_Data_Package_Biomaterial add
            constraint FK_T_Data_Package_Biomaterial_T_Data_Package foreign key(Data_Package_ID) references T_Data_Package(ID) on delete cascade;

        alter table T_Data_Package_Datasets add
            constraint FK_T_Data_Package_Datasets_T_Data_Package foreign key(Data_Package_ID) references T_Data_Package(ID) on delete cascade;

        alter table T_Data_Package_EUS_Proposals add
            constraint FK_T_Data_Package_EUS_Proposals_T_Data_Package foreign key(Data_Package_ID) references T_Data_Package(ID) on delete cascade;

        alter table T_Data_Package_Experiments add
            constraint FK_T_Data_Package_Experiments_T_Data_Package foreign key(Data_Package_ID) references T_Data_Package(ID) on delete cascade;

    End

Done:
    If @message <> ''
        Print @message

    return @myError
GO
