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
	[Path_Root] [int] NULL,
	[Sample_Prep_Requests] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_OSM_Package] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_OSM_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_Storage] FOREIGN KEY([Path_Root])
REFERENCES [T_OSM_Package_Storage] ([ID])
GO
ALTER TABLE [dbo].[T_OSM_Package] CHECK CONSTRAINT [FK_T_OSM_Package_T_OSM_Package_Storage]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Packa__53D770D6]  DEFAULT ('General') FOR [Package_Type]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Descr__54CB950F]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Comme__55BFB948]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__Creat__56B3DD81]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF_T_OSM_Package_Last_Modified]  DEFAULT (getdate()) FOR [Last_Modified]
GO
ALTER TABLE [dbo].[T_OSM_Package] ADD  CONSTRAINT [DF__T_OSM_Pac__State__57A801BA]  DEFAULT ('Active') FOR [State]
GO
