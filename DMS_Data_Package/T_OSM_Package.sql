/****** Object:  Table [dbo].[T_OSM_Package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_OSM_Package](
	[ID] [int] IDENTITY(100,1) NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Package_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Keywords] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Last_Modified] [datetime] NOT NULL,
	[State] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Wiki_Page_Link] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Prep_Requests] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Path_Root] [int] NULL,
	[User_Folder_Path] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_OSM_Package] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_OSM_Package] TO [DDL_Viewer] AS [dbo]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Package_Type]  DEFAULT ('General') FOR [Package_Type]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Last_Modified]  DEFAULT (getdate()) FOR [Last_Modified]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_State]  DEFAULT ('Active') FOR [State]
GO
ALTER TABLE [dbo].[T_OSM_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_State] FOREIGN KEY([State])
REFERENCES [dbo].[T_OSM_Package_State] ([Name])
GO
ALTER TABLE [dbo].[T_OSM_Package] CHECK CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_State]
GO
ALTER TABLE [dbo].[T_OSM_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_Storage] FOREIGN KEY([Path_Root])
REFERENCES [dbo].[T_OSM_Package_Storage] ([ID])
GO
ALTER TABLE [dbo].[T_OSM_Package] CHECK CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_Storage]
GO
ALTER TABLE [dbo].[T_OSM_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_Type] FOREIGN KEY([Package_Type])
REFERENCES [dbo].[T_OSM_Package_Type] ([Name])
GO
ALTER TABLE [dbo].[T_OSM_Package] CHECK CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_Type]
GO
