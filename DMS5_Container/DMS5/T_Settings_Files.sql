/****** Object:  Table [dbo].[T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Settings_Files](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Analysis_Tool] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NULL,
	[Last_Updated] [datetime] NULL,
	[Contents] [xml] NULL,
	[Job_Usage_Count] [int] NULL,
 CONSTRAINT [PK_T_Settings_Files] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Settings_Files_Analysis_Tool_File_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Settings_Files_Analysis_Tool_File_Name] ON [dbo].[T_Settings_Files] 
(
	[Analysis_Tool] ASC,
	[File_Name] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
/****** Object:  Trigger [dbo].[trig_d_T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_d_T_Settings_Files] on [dbo].[T_Settings_Files]
For Delete
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Settings_Files_XML_History(
			Event_Action, ID, 
            Analysis_Tool, File_Name, 
			Description, Contents,
			Entered, Entered_By )
	SELECT 'Delete' AS Event_Action, ID, 
           Analysis_Tool, File_Name,
		   Description, Contents,
		   GetDate(), SYSTEM_USER
	FROM deleted

GO
/****** Object:  Trigger [dbo].[trig_i_T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_i_T_Settings_Files] on [dbo].[T_Settings_Files]
For Insert
AS
	If @@RowCount = 0
		Return

	INSERT INTO T_Settings_Files_XML_History(
			Event_Action, ID, 
            Analysis_Tool, File_Name, 
			Description, Contents,
			Entered, Entered_By )
	SELECT 'Create' AS Event_Action, ID, 
           Analysis_Tool, File_Name,
	       Description, Contents,
	       GetDate(), SYSTEM_USER
	FROM inserted


GO
/****** Object:  Trigger [dbo].[trig_u_T_Settings_Files] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Trigger [dbo].[trig_u_T_Settings_Files] on [dbo].[T_Settings_Files]
For Update
AS
	If @@RowCount = 0
		Return

	if update(Analysis_Tool) or 
	   update(File_Name) or 
	   update(Contents)
		INSERT INTO T_Settings_Files_XML_History(
				Event_Action, ID, 
                Analysis_Tool, File_Name, 
				Description, Contents,
				Entered, Entered_By )
		SELECT 'Update' AS Event_Action, ID, 
               Analysis_Tool, File_Name,
			   Description, Contents,
			   GetDate(), SYSTEM_USER
		FROM inserted

GO
GRANT DELETE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT INSERT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Settings_Files] TO [Limited_Table_Write] AS [dbo]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [FK_T_Settings_Files_T_Settings_Files] FOREIGN KEY([Analysis_Tool])
REFERENCES [T_Analysis_Tool] ([AJT_toolName])
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [FK_T_Settings_Files_T_Settings_Files]
GO
ALTER TABLE [dbo].[T_Settings_Files]  WITH CHECK ADD  CONSTRAINT [CK_T_Settings_Files_SettingsFileName_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([File_Name],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Settings_Files] CHECK CONSTRAINT [CK_T_Settings_Files_SettingsFileName_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Active]  DEFAULT ((1)) FOR [Active]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Last_Updated]  DEFAULT (getdate()) FOR [Last_Updated]
GO
ALTER TABLE [dbo].[T_Settings_Files] ADD  CONSTRAINT [DF_T_Settings_Files_Job_Usage_Count]  DEFAULT ((0)) FOR [Job_Usage_Count]
GO
