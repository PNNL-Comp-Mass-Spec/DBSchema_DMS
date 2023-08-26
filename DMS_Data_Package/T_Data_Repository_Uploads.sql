/****** Object:  Table [dbo].[T_Data_Repository_Uploads] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Repository_Uploads](
	[Upload_ID] [int] IDENTITY(1,1) NOT NULL,
	[Repository_ID] [int] NOT NULL,
	[Title] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Upload_Date] [datetime] NULL,
	[Accession] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Contact] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Data_Repository_Uploads] PRIMARY KEY CLUSTERED 
(
	[Upload_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Data_Repository_Uploads_Accession] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Repository_Uploads_Accession] ON [dbo].[T_Data_Repository_Uploads]
(
	[Accession] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Data_Repository_Uploads]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Repository_Uploads_T_Data_Repository] FOREIGN KEY([Repository_ID])
REFERENCES [dbo].[T_Data_Repository] ([Repository_ID])
GO
ALTER TABLE [dbo].[T_Data_Repository_Uploads] CHECK CONSTRAINT [FK_T_Data_Repository_Uploads_T_Data_Repository]
GO
