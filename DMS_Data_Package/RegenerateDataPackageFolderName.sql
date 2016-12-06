/****** Object:  StoredProcedure [dbo].[RegenerateDataPackageFolderName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.RegenerateDataPackageFolderName
/****************************************************
**
**  Desc:	Updates the auto-generated data package folder name for a given data package
**			Also updates the auto-generated wiki name (unless @UpdateWikiLink = 0)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	mem
**	Date:	06/09/2009
**			06/26/2009 mem - Now also updating the wiki page (if parameter @UpdateWikiLink is 1)
**			10/23/2009 mem - Expanded @CurrentDataPackageWiki and @NewDataPackageWiki to varchar(1024)
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
	@DataPkgID int,				-- ID of the data package to update
	@infoOnly tinyint = 1,		-- 0 to update the name, 1 to preview the new name
	@UpdateWikiLink tinyint = 1,		-- 1 to update the Wiki Link; 0 to not update the link
	@message varchar(512) = '' output,
	@callingUser varchar(128) = ''
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	declare @DataPackageName varchar(256)
	declare @CurrentDataPkgID int
	declare @CurrentDataPackageFolder varchar(256)
	declare @CurrentDataPackageWiki varchar(1024)
	
	declare @NewDataPackageFolder varchar(256)
	declare @NewDataPackageWiki varchar(1024)
	
	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 1)
	set @message = ''
	 
	If @DataPkgID Is Null
	Begin
		set @message = 'Data Package ID cannot be null; unable to continue'
		RAISERROR (@message, 10, 1)
		return 51005
	End

	---------------------------------------------------
	-- Lookup the current name for this data package
	---------------------------------------------------
	--
	set @CurrentDataPkgID = 0
	--
	SELECT @CurrentDataPkgID = ID,
	       @DataPackageName = [Name],
		   @CurrentDataPackageFolder = Package_File_Folder,
		   @CurrentDataPackageWiki = Wiki_Page_Link
	FROM T_Data_Package
	WHERE (ID = @DataPkgID)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0 OR @CurrentDataPkgID = 0
	begin
		set @message = 'No entry could be found in database for data package: ' + @DataPkgID
		RAISERROR (@message, 10, 1)
		return 51006
	end
	
	-- Generate the new data package folder name
	Set @NewDataPackageFolder = dbo.MakePackageFolderName(@DataPkgID, @DataPackageName)
	
	If @UpdateWikiLink = 0
		Set @NewDataPackageWiki = @CurrentDataPackageWiki
	Else
		Set @NewDataPackageWiki = dbo.MakePRISMWikiPageLink(@DataPkgID, @DataPackageName)
	
	If @NewDataPackageFolder = @CurrentDataPackageFolder
	Begin
		Set @message = 'Data package folder name is already up-to-date: ' + @NewDataPackageFolder
		If @infoOnly <> 0
			SELECT @message AS Message
	End
	Else
	Begin
		If @infoOnly <> 0
		Begin
			set @message = 'Will change data package folder name from "' + @CurrentDataPackageFolder + '" to "' + @NewDataPackageFolder + '"'
			SELECT @message AS Message
		End
		Else
		Begin
			UPDATE T_Data_Package
			SET Package_File_Folder = @NewDataPackageFolder
			WHERE ID = @DataPkgID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error updating data package folder to "' + @NewDataPackageFolder + '" for data package: ' + Convert(varchar(12), @DataPkgID)
				RAISERROR (@message, 10, 1)
				return 51007
			end		

			set @message = 'Changed data package folder name to "' + @NewDataPackageFolder + '" for ID ' + Convert(varchar(12), @DataPkgID)

		End
	End

	If @NewDataPackageWiki = @CurrentDataPackageWiki
	Begin
		Set @message = 'Data package wiki link is already up-to-date: ' + @NewDataPackageWiki
		If @infoOnly <> 0
			SELECT @message AS Message
	End
	Else
	Begin
		If @infoOnly <> 0
		Begin
			set @message = 'Will change data package wiki link from "' + @CurrentDataPackageWiki + '" to "' + @NewDataPackageWiki + '"'
			SELECT @message AS Message
		End
		Else
		Begin
			UPDATE T_Data_Package
			SET Wiki_Page_Link = @NewDataPackageWiki
			WHERE ID = @DataPkgID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--
			if @myError <> 0
			begin
				set @message = 'Error updating data package wiki link to "' + @NewDataPackageWiki + '" for data package: ' + Convert(varchar(12), @DataPkgID)
				RAISERROR (@message, 10, 1)
				return 51007
			end		

			set @message = 'Changed data package wiki link to "' + @NewDataPackageWiki + '" for ID ' + Convert(varchar(12), @DataPkgID)

		End
	End
	
	---------------------------------------------------
	-- 
	---------------------------------------------------

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[RegenerateDataPackageFolderName] TO [DDL_Viewer] AS [dbo]
GO
