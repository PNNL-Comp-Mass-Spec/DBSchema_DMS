/****** Object:  Table [dbo].[T_Material_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Locations](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Tag] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Freezer] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Shelf] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Rack] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Row] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Col] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Status] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Barcode] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Container_Limit] [int] NOT NULL,
 CONSTRAINT [PK_T_Material_Locations] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_T_Material_Locations] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Material_Locations] ON [dbo].[T_Material_Locations] 
(
	[Tag] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Index [IX_T_Material_Locations_ID_include_Tag] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Locations_ID_include_Tag] ON [dbo].[T_Material_Locations] 
(
	[ID] ASC
)
INCLUDE ( [Tag]) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Material_Locations]  WITH CHECK ADD  CONSTRAINT [CK_T_Material_Locations_Tag_WhiteSpace] CHECK  (([dbo].[udfWhitespaceChars]([Tag],(0))=(0)))
GO
ALTER TABLE [dbo].[T_Material_Locations] CHECK CONSTRAINT [CK_T_Material_Locations_Tag_WhiteSpace]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Shelf]  DEFAULT ('na') FOR [Shelf]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Rack]  DEFAULT ('na') FOR [Rack]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Row]  DEFAULT ('na') FOR [Row]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Box]  DEFAULT ('na') FOR [Col]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Status]  DEFAULT ('Active') FOR [Status]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Container_Limit]  DEFAULT ((1)) FOR [Container_Limit]
GO
