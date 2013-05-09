/****** Object:  Table [dbo].[T_OSM_Package_Items] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_OSM_Package_Items](
	[OSM_Package_ID] [int] NOT NULL,
	[Item_ID] [int] NOT NULL,
	[Item] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Item_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Item Added] [datetime] NOT NULL,
	[Package Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_OSM_Package_Item] PRIMARY KEY CLUSTERED 
(
	[OSM_Package_ID] ASC,
	[Item_ID] ASC,
	[Item_Type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_OSM_Package_Items]  WITH CHECK ADD  CONSTRAINT [FK_T_OSM_Package_Items_T_OSM_Package] FOREIGN KEY([OSM_Package_ID])
REFERENCES [T_OSM_Package] ([ID])
GO
ALTER TABLE [dbo].[T_OSM_Package_Items] CHECK CONSTRAINT [FK_T_OSM_Package_Items_T_OSM_Package]
GO
ALTER TABLE [dbo].[T_OSM_Package_Items] ADD  CONSTRAINT [DF__T_OSM_Pac__Item __65F62111]  DEFAULT (getdate()) FOR [Item Added]
GO
