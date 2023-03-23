/****** Object:  StoredProcedure [dbo].[update_user_permissions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_user_permissions]
/****************************************************
**
**  Desc: Updates user permissions in the current DB
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   12/13/2004
**          01/27/2005 mem - Added MTS_DB_Dev and MTS_DB_Lite
**          07/15/2006 mem - Updated to use Sql Server 2005 syntax if possible
**          08/10/2006 mem - Added MTS_DB_Reader
**          11/20/2006 mem - Added DMS Logins
**          07/31/2012 mem - Removed references to emsl-prism.Users.DMS_JobRunner
**                         - Added stored procedure and table permissions
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
AS
    Set NoCount On

    ---------------------------------------------------
    -- Determine whether or not we're running Sql Server 2005 or newer
    ---------------------------------------------------
    Declare @VersionMajor int
    Declare @UseSystemViews tinyint
    Declare @S nvarchar(256)

    if exists (select * from sys.schemas where name = 'MTUser')
        drop schema MTUser
    if exists (select * from sys.sysusers where name = 'MTUser')
        drop user MTUser
    create user MTUser for login MTUser
    exec sp_addrolemember 'db_datareader', 'MTUser'
    exec sp_addrolemember 'DMS_Analysis', 'MTUser'
    exec sp_addrolemember 'DMS_User', 'MTUser'
    exec sp_addrolemember 'MTS_SP_User', 'MTUser'

    if exists (select * from sys.schemas where name = 'MTAdmin')
        drop schema MTAdmin
    if exists (select * from sys.sysusers where name = 'MTAdmin')
        drop user MTAdmin
    create user MTAdmin for login MTAdmin
    exec sp_addrolemember 'db_datareader', 'MTAdmin'
    exec sp_addrolemember 'db_datawriter', 'MTAdmin'
    exec sp_addrolemember 'MTS_SP_User', 'MTAdmin'

    if exists (select * from sys.schemas where name = 'MTS_DB_Dev')
        drop schema MTS_DB_Dev
    if exists (select * from sys.sysusers where name = 'MTS_DB_Dev')
        drop user MTS_DB_Dev

    set @S = 'create user MTS_DB_Dev for login [' + @@ServerName + '\MTS_DB_Dev]'
    exec sp_executesql @S

    exec sp_addrolemember 'db_owner', 'MTS_DB_DEV'
    exec sp_addrolemember 'db_ddladmin', 'MTS_DB_DEV'
    exec sp_addrolemember 'db_backupoperator', 'MTS_DB_DEV'
    exec sp_addrolemember 'db_datareader', 'MTS_DB_DEV'
    exec sp_addrolemember 'db_datawriter', 'MTS_DB_DEV'
    exec sp_addrolemember 'MTS_SP_User', 'MTS_DB_DEV'

    if exists (select * from sys.schemas where name = 'MTS_DB_Lite')
        drop schema MTS_DB_Lite
    if exists (select * from sys.sysusers where name = 'MTS_DB_Lite')
        drop user MTS_DB_Lite


    set @S = 'create user MTS_DB_Lite for login [' + @@ServerName + '\MTS_DB_Lite]'
    exec sp_executesql @S
    exec sp_addrolemember 'db_datareader', 'MTS_DB_Lite'
    exec sp_addrolemember 'db_datawriter', 'MTS_DB_Lite'
    exec sp_addrolemember 'MTS_SP_User', 'MTS_DB_Lite'


    if exists (select * from sys.schemas where name = 'MTS_DB_Reader')
        drop schema MTS_DB_Reader
    if exists (select * from sys.sysusers where name = 'MTS_DB_Reader')
        drop user MTS_DB_Reader

    set @S = 'create user MTS_DB_Reader for login [' + @@ServerName + '\MTS_DB_Reader]'
    exec sp_executesql @S

    exec sp_addrolemember 'db_datareader', 'MTS_DB_Reader'
    exec sp_addrolemember 'MTS_SP_User', 'MTS_DB_Reader'


    if exists (select * from sys.schemas where name = 'DMSReader')
        drop schema DMSReader
    if exists (select * from sys.sysusers where name = 'DMSReader')
        drop user DMSReader
    create user DMSReader for login DMSReader
    exec sp_addrolemember 'db_datareader', 'DMSReader'
    exec sp_addrolemember 'MTS_SP_User', 'DMSReader'


    if exists (select * from sys.schemas where name = 'DMSWebUser')
        drop schema DMSWebUser
    if exists (select * from sys.sysusers where name = 'DMSWebUser')
        drop user DMSWebUser
    create user DMSWebUser for login DMSWebUser
    exec sp_addrolemember 'db_datareader', 'DMSWebUser'
    exec sp_addrolemember 'MTS_SP_User', 'DMSWebUser'


    if exists (select * from sys.schemas where name = 'PRISMSeqReader')
        drop schema PRISMSeqReader
    if exists (select * from sys.sysusers where name = 'PRISMSeqReader')
        drop user PRISMSeqReader
    create user PRISMSeqReader for login PRISMSeqReader
    exec sp_addrolemember 'db_datareader', 'PRISMSeqReader'
    exec sp_addrolemember 'MTS_SP_User', 'PRISMSeqReader'


    if exists (select * from sys.schemas where name = 'EMSL-Prism.Users.DMS_User')
        drop schema [EMSL-Prism.Users.DMS_User]
    if exists (select * from sys.sysusers where name = 'EMSL-Prism.Users.DMS_User')
        drop user [EMSL-Prism.Users.DMS_User]

    set @S = 'create user [EMSL-Prism.Users.DMS_User] for login [pnl\EMSL-Prism.Users.DMS_User]'
    exec sp_executesql @S

    exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_User'
    exec sp_addrolemember 'DMS_User', 'EMSL-Prism.Users.DMS_User'
    exec sp_addrolemember 'MTS_SP_User', 'EMSL-Prism.Users.DMS_User'


    if exists (select * from sys.schemas where name = 'EMSL-Prism.Users.DMS_Guest')
        drop schema [EMSL-Prism.Users.DMS_Guest]
    if exists (select * from sys.sysusers where name = 'EMSL-Prism.Users.DMS_Guest')
        drop user [EMSL-Prism.Users.DMS_Guest]

    set @S = 'create user [EMSL-Prism.Users.DMS_Guest] for login [pnl\EMSL-Prism.Users.DMS_Guest]'
    exec sp_executesql @S

    exec sp_addrolemember 'db_datareader', 'EMSL-Prism.Users.DMS_Guest'


    if exists (select * from sys.schemas where name = 'RBAC-Web_Analysis')
        drop schema [RBAC-Web_Analysis]
    if exists (select * from sys.sysusers where name = 'RBAC-Web_Analysis')
        drop user [RBAC-Web_Analysis]
    if exists (select * from sys.schemas where name = 'emsl-prism.Users.Web_Analysis')
        drop schema [emsl-prism.Users.Web_Analysis]
    if exists (select * from sys.sysusers where name = 'emsl-prism.Users.Web_Analysis')
        drop user [emsl-prism.Users.Web_Analysis]

    set @S = 'create user [emsl-prism.Users.Web_Analysis] for login [pnl\emsl-prism.Users.Web_Analysis]'
    exec sp_executesql @S

    exec sp_addrolemember 'db_datareader', 'emsl-prism.Users.Web_Analysis'
    exec sp_addrolemember 'DMS_Analysis', 'emsl-prism.Users.Web_Analysis'
    exec sp_addrolemember 'MTS_SP_User', 'emsl-prism.Users.Web_Analysis'


    exec sp_addrolemember 'db_datareader', 'ProteinSeqs\ProteinSeqs_Upload_Users'
    exec sp_addrolemember 'DMS_Analysis', 'ProteinSeqs\ProteinSeqs_Upload_Users'
    exec sp_addrolemember 'MTS_SP_User', 'ProteinSeqs\ProteinSeqs_Upload_Users'


    -- Stored procedure permissions

    GRANT EXECUTE ON [dbo].[add_annotation_type] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_archived_file_entry_xref] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_archived_file_entry_xref] TO [svc-dms] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_collection_organism_xref] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_crc32_file_authentication] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_legacy_file_upload_request] TO [svc-dms] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_naming_authority] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_output_file_archive_entry] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_output_file_archive_entry] TO [svc-dms] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_output_file_archive_entry_New] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_protein_reference] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_protein_sequence] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_sha1_file_authentication] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_encryption_metadata] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_protein_collection] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_protein_collectionMember] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[add_update_protein_collection_member] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[delete_protein_collection_members] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_annotation_type_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_archived_file_id_for_protein_collection_list] TO [MTS_SP_User] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_archived_file_id_for_protein_collection_list] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_naming_authority_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_protein_collection_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_protein_collection_member_count] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_protein_collection_state] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_protein_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_protein_id_from_name] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[get_protein_reference_id] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[standardize_protein_collection_list] TO [DMS_Analysis] AS [dbo]
    GRANT EXECUTE ON [dbo].[standardize_protein_collection_list] TO [DMS_User] AS [dbo]
    GRANT EXECUTE ON [dbo].[standardize_protein_collection_list] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_file_archive_entry_collection_list] TO [svc-dms] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_protein_collection_state] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_protein_name_hash] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_protein_sequence_hash] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_protein_sequence_info] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[update_user_permissions] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
    GRANT EXECUTE ON [dbo].[validate_analysis_job_protein_parameters] TO [DMS_Analysis] AS [dbo]
    GRANT EXECUTE ON [dbo].[validate_analysis_job_protein_parameters] TO [DMS_User] AS [dbo]
    GRANT EXECUTE ON [dbo].[validate_analysis_job_protein_parameters] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]

    GRANT VIEW DEFINITION ON [dbo].[rebuild_fragmented_indices] TO [MTS_DB_Dev] AS [dbo]
    GRANT VIEW DEFINITION ON [dbo].[rebuild_fragmented_indices] TO [MTS_DB_Lite] AS [dbo]
    GRANT VIEW DEFINITION ON [dbo].[reindex_database] TO [MTS_DB_Dev] AS [dbo]
    GRANT VIEW DEFINITION ON [dbo].[reindex_database] TO [MTS_DB_Lite] AS [dbo]
    GRANT VIEW DEFINITION ON [dbo].[verify_update_enabled] TO [MTS_DB_Dev] AS [dbo]
    GRANT VIEW DEFINITION ON [dbo].[verify_update_enabled] TO [MTS_DB_Lite] AS [dbo]


    -- Table permissions
    GRANT DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [BUILTIN\Administrators] AS [dbo]
    GRANT DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
    GRANT INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [BUILTIN\Administrators] AS [dbo]
    GRANT INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
    GRANT REFERENCES ON [dbo].[T_Encrypted_Collection_Authorizations] TO [BUILTIN\Administrators] AS [dbo]
    GRANT REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [BUILTIN\Administrators] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\D3E383] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\d3l243] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [public] AS [dbo]
    GRANT SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]
    GRANT UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [BUILTIN\Administrators] AS [dbo]
    GRANT UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [BUILTIN\Administrators] AS [dbo]

    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSReader] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSWebUser] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\D3E383] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\d3l243] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [public] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY DELETE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSReader] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSWebUser] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\D3E383] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\d3l243] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [public] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY INSERT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSReader] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSWebUser] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Authorizations] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Authorizations] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY REFERENCES ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSReader] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSWebUser] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY SELECT ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSReader] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [DMSWebUser] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\D3E383] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [pnl\d3l243] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Authorizations] TO [public] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSReader] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [DMSWebUser] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [EMSL-Prism.Users.DMS_User] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\D3E383] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [pnl\d3l243] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [PNL\EMSL-Prism.Users.DMS_Guest] AS [dbo]
    DENY UPDATE ON [dbo].[T_Encrypted_Collection_Passphrases] TO [public] AS [dbo]


    Return 0

GO
GRANT EXECUTE ON [dbo].[update_user_permissions] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
