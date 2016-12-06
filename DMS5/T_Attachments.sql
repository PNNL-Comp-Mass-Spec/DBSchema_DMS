/****** Object:  Table [dbo].[T_Attachments] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Attachments](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Attachment_Type] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Attachment_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Attachment_Description] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner_PRN] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Active] [varchar](8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Contents] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[File_Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Created] [datetime] NOT NULL,
 CONSTRAINT [PK_T_Attachments] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Attachments] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Attachments] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Attachments] ON [dbo].[T_Attachments]
(
	[Attachment_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Attachments] ADD  CONSTRAINT [DF_T_Attachments_Active]  DEFAULT ('Y') FOR [Active]
GO
ALTER TABLE [dbo].[T_Attachments] ADD  CONSTRAINT [DF_T_Attachments_Created]  DEFAULT (getdate()) FOR [Created]
GO
