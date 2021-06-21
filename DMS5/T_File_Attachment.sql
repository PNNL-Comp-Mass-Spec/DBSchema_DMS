/****** Object:  Table [dbo].[T_File_Attachment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_File_Attachment](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[File_Name] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entity_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Entity_ID] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Entity_ID_Value] [int] NULL,
	[Owner_PRN] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Size_Bytes] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Last_Affected] [datetime] NOT NULL,
	[Archive_Folder_Path] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[File_Mime_Type] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_File_Attachment] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_File_Attachment] TO [DDL_Viewer] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_File_Attachment] TO [DMSWebUser] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_File_Attachment_EntityType_Active_EntityIdValue] ******/
CREATE NONCLUSTERED INDEX [IX_T_File_Attachment_EntityType_Active_EntityIdValue] ON [dbo].[T_File_Attachment]
(
	[Entity_Type] ASC,
	[Active] ASC
)
INCLUDE([Entity_ID_Value]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_File_Attachment_EntityType_Active_include_EntityID] ******/
CREATE NONCLUSTERED INDEX [IX_T_File_Attachment_EntityType_Active_include_EntityID] ON [dbo].[T_File_Attachment]
(
	[Entity_Type] ASC,
	[Active] ASC
)
INCLUDE([Entity_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_File_Attachment] ADD  CONSTRAINT [DF_T_File_Attachment_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_File_Attachment] ADD  CONSTRAINT [DF_T_File_Attachment_Last_Affected]  DEFAULT (getdate()) FOR [Last_Affected]
GO
ALTER TABLE [dbo].[T_File_Attachment] ADD  CONSTRAINT [DF_T_File_Attachment_Active]  DEFAULT ((1)) FOR [Active]
GO
