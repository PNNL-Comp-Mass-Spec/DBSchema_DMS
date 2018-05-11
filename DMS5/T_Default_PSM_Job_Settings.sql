/****** Object:  Table [dbo].[T_Default_PSM_Job_Settings] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Default_PSM_Job_Settings](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Tool_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Job_Type_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[StatCysAlk] [tinyint] NOT NULL,
	[DynSTYPhos] [tinyint] NOT NULL,
	[Settings_File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Enabled] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_Default_PSM_Job_Settings] PRIMARY KEY CLUSTERED 
(
	[Tool_Name] ASC,
	[Job_Type_Name] ASC,
	[StatCysAlk] ASC,
	[DynSTYPhos] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Default_PSM_Job_Settings] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Settings] ADD  CONSTRAINT [DF_T_Default_PSM_Job_Settings_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Settings]  WITH CHECK ADD  CONSTRAINT [FK_T_Default_PSM_Job_Settings_T_Analysis_Tool] FOREIGN KEY([Tool_Name])
REFERENCES [dbo].[T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Settings] CHECK CONSTRAINT [FK_T_Default_PSM_Job_Settings_T_Analysis_Tool]
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Settings]  WITH CHECK ADD  CONSTRAINT [FK_T_Default_PSM_Job_Settings_T_Default_PSM_Job_Types] FOREIGN KEY([Job_Type_Name])
REFERENCES [dbo].[T_Default_PSM_Job_Types] ([Job_Type_Name])
GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Settings] CHECK CONSTRAINT [FK_T_Default_PSM_Job_Settings_T_Default_PSM_Job_Types]
GO
/****** Object:  Trigger [dbo].[trig_iu_T_Default_PSM_Job_Settings] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_iu_T_Default_PSM_Job_Settings] on [dbo].[T_Default_PSM_Job_Settings]
For Insert, Update
/****************************************************
**
**	Desc: 
**		Validates that the settings file name is valid
**
**	Auth:	mem
**	Date:	11/13/2012 mem - Initial version
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Declare @ToolName varchar(255)
	Declare @message varchar(512)

	If Update(Tool_Name) OR Update(Settings_File_Name)
	Begin
		-- Make sure Settings_File_Name is valid
		Declare @SettingsFileName varchar(255)
		
		SELECT TOP 1 @ToolName = I.Tool_Name,
		             @SettingsFileName = I.Settings_File_Name
		FROM inserted I
		     LEFT OUTER JOIN T_Settings_Files SF
		       ON I.Tool_Name = SF.Analysis_Tool AND
		          I.Settings_File_Name = SF.File_Name
		WHERE I.Settings_File_Name IS NOT NULL AND
		      SF.File_Name IS NULL
		
		If ISNULL(@SettingsFileName, '') <> ''
		Begin
			Set @message = 'Settings file ' + ISNULL(@SettingsFileName, '??') + ' is not defined for tool ' + ISNULL(@ToolName, '???') + ' in T_Settings_Files (see trigger trig_iu_T_Default_PSM_Job_Settings)'
			
			RAISERROR(@message,16,1)
	        ROLLBACK TRANSACTION
		    RETURN
		End
	End

GO
ALTER TABLE [dbo].[T_Default_PSM_Job_Settings] ENABLE TRIGGER [trig_iu_T_Default_PSM_Job_Settings]
GO
