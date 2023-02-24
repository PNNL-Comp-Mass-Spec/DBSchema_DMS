/****** Object:  StoredProcedure [dbo].[validate_auto_storage_path_params] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_auto_storage_path_params]
/****************************************************
**
**  Desc:   Validates that the Auto storage path parameters are correct
**
**  Returns: The storage path ID; 0 if an error
**
**  Auth:   mem
**  Date:   05/13/2011 mem - Initial version
**          07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov\archive\dmsarch\
**          09/02/2016 mem - Archive path is now adms.emsl.pnl.gov\dmsarch\
**          09/08/2020 mem - When @AutoDefineStoragePath is positive, raise an error if any of the paths are \ or /
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @autoDefineStoragePath tinyint,
    @autoSPVolNameClient varchar(128),
    @autoSPVolNameServer varchar(128),
    @autoSPPathRoot varchar(128),
    @autoSPArchiveServerName varchar(64),
    @autoSPArchivePathRoot varchar(128),
    @autoSPArchiveSharePathRoot varchar(128)
)
AS
    Set NoCount On

    Set @AutoSPVolNameClient = LTrim(RTrim(IsNull(@AutoSPVolNameClient, '')))
    Set @AutoSPVolNameServer = LTrim(RTrim(IsNull(@AutoSPVolNameServer, '')))
    Set @AutoSPPathRoot = LTrim(RTrim(IsNull(@AutoSPPathRoot, '')))
    Set @AutoSPArchiveServerName = LTrim(RTrim(IsNull(@AutoSPArchiveServerName, '')))
    Set @AutoSPArchivePathRoot = LTrim(RTrim(IsNull(@AutoSPArchivePathRoot, '')))
    Set @AutoSPArchiveSharePathRoot = LTrim(RTrim(IsNull(@AutoSPArchiveSharePathRoot, '')))

    If @AutoDefineStoragePath > 0
    Begin
        If @AutoSPVolNameClient IN ('', '\', '/')
            RAISERROR ('Auto Storage VolNameClient cannot be blank or \ or /', 11, 4)
        If @AutoSPVolNameServer IN ('', '\', '/')
            RAISERROR ('Auto Storage VolNameServer cannot be blank or \ or /', 11, 4)
        If @AutoSPPathRoot IN ('', '\', '/')
            RAISERROR ('Auto Storage Path Root cannot be blank or \ or /', 11, 4)
        If @AutoSPArchiveServerName IN ('', '\', '/')
            RAISERROR ('Auto Storage Archive Server Name cannot be blank or \ or /', 11, 4)
        If @AutoSPArchivePathRoot IN ('', '\', '/')
            RAISERROR ('Auto Storage Archive Path Root cannot be blank or \ or /', 11, 4)
        If @AutoSPArchiveSharePathRoot IN ('', '\', '/')
            RAISERROR ('Auto Storage Archive Share Path Root cannot be blank or \ or /', 11, 4)
    End

    If @AutoSPVolNameClient <> ''
    Begin
        If @AutoSPVolNameClient Not Like '\\%'
            RAISERROR ('Auto Storage VolNameClient should be a network share, for example: \\Proto-3\', 11, 4)

        If @AutoSPVolNameClient Not Like '%\'
            RAISERROR ('Auto Storage VolNameClient must end in a backslash, for example: \\Proto-3\', 11, 4)
    End

    If @AutoSPVolNameServer <> ''
    Begin
        If @AutoSPVolNameServer Not Like '[A-Z]:%'
            RAISERROR ('Auto Storage VolNameServer should be a drive letter, for example: G:\', 11, 4)

        If @AutoSPVolNameServer Not Like '%\'
            RAISERROR ('Auto Storage VolNameServer must end in a backslash, for example: G:\', 11, 4)
    End

    If @AutoSPArchivePathRoot <> ''
    Begin
        If @AutoSPArchivePathRoot Not Like '/%'
            RAISERROR ('Auto Storage Archive Path Root should be a linux path, for example: /archive/dmsarch/Broad_Orb1', 11, 4)

    End

    If @AutoSPArchiveSharePathRoot <> ''
    Begin
        If @AutoSPArchiveSharePathRoot Not Like '\\%'
            RAISERROR ('Auto Storage Archive Share Path Root should be a network share, for example: \\adms.emsl.pnl.gov\dmsarch\VOrbiETD01', 11, 4)
    End

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[validate_auto_storage_path_params] TO [DDL_Viewer] AS [dbo]
GO
