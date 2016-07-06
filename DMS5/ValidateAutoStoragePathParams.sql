/****** Object:  StoredProcedure [dbo].[ValidateAutoStoragePathParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE ValidateAutoStoragePathParams
/****************************************************
**
**	Desc:	Validates that the Auto storage path parameters are correct
**
**	Returns: The storage path ID; 0 if an error
**
**	Auth:	mem
**	Date:	05/13/2011 mem - Initial version
**			07/05/2016 mem - Archive path is now aurora.emsl.pnl.gov
**    
*****************************************************/
(
	@AutoDefineStoragePath tinyint,
	@AutoSPVolNameClient varchar(128),
	@AutoSPVolNameServer varchar(128),
	@AutoSPPathRoot varchar(128),
	@AutoSPArchiveServerName varchar(64),
	@AutoSPArchivePathRoot varchar(128),
	@AutoSPArchiveSharePathRoot varchar(128)

)
AS
	Set NoCount On


	If @AutoDefineStoragePath = 1	 
	Begin
		If IsNull(@AutoSPVolNameClient, '') = ''
			RAISERROR ('Auto Storage VolNameClient cannot be blank', 11, 4)
		If IsNull(@AutoSPVolNameServer, '') = ''
			RAISERROR ('Auto Storage VolNameServer cannot be blank', 11, 4)
		If IsNull(@AutoSPPathRoot, '') = ''
			RAISERROR ('Auto Storage Path Root cannot be blank', 11, 4)
		If IsNull(@AutoSPArchiveServerName, '') = ''
			RAISERROR ('Auto Storage Archive Server Name cannot be blank', 11, 4)
		If IsNull(@AutoSPArchivePathRoot, '') = ''
			RAISERROR ('Auto Storage Archive Path Root cannot be blank', 11, 4)
		If IsNull(@AutoSPArchiveSharePathRoot, '') = ''
			RAISERROR ('Auto Storage Archive Share Path Root cannot be blank', 11, 4)
		   
	End
	
	If IsNull(@AutoSPVolNameClient, '') <> ''
	Begin
		If @AutoSPVolNameClient Not Like '\\%'
			RAISERROR ('Auto Storage VolNameClient should be a network share, for example: \\Proto-3\', 11, 4)
		
		If @AutoSPVolNameClient Not Like '%\'
			RAISERROR ('Auto Storage VolNameClient must end in a backslash, for example: \\Proto-3\', 11, 4)
	End
	
	If IsNull(@AutoSPVolNameServer, '') <> ''
	Begin
		If @AutoSPVolNameServer Not Like '[A-Z]:%'
			RAISERROR ('Auto Storage VolNameServer should be a drive letter, for example: G:\', 11, 4)
		
		If @AutoSPVolNameServer Not Like '%\'
			RAISERROR ('Auto Storage VolNameServer must end in a backslash, for example: G:\', 11, 4)
	End
	
	If IsNull(@AutoSPArchivePathRoot, '') <> ''
	Begin
		If @AutoSPArchivePathRoot Not Like '/%'
			RAISERROR ('Auto Storage Archive Path Root should be a linux path, for example: /archive/dmsarch/Broad_Orb1', 11, 4)
		
	End
	
	If IsNull(@AutoSPArchiveSharePathRoot, '') <> ''
	Begin
		If @AutoSPArchiveSharePathRoot Not Like '\\%'
			RAISERROR ('Auto Storage Archive Share Path Root should be a network share, for example: \\aurora.emsl.pnl.gov\archive\dmsarch\VOrbiETD01', 11, 4)
	End	


	return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateAutoStoragePathParams] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateAutoStoragePathParams] TO [PNL\D3M580] AS [dbo]
GO
