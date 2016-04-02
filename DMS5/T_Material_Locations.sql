/****** Object:  Table [dbo].[T_Material_Locations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Locations](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Tag]  AS (case when [Freezer_Tag]='None' OR [Freezer_Tag]='-80_Staging' OR [Freezer_Tag]='-20_Staging' then [Freezer_Tag] else ((((((([Freezer_Tag]+'.')+[Shelf])+'.')+[Rack])+'.')+[Row])+'.')+[Col] end) PERSISTED NOT NULL,
	[Freezer_Tag] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_Material_Locations] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Material_Locations] ON [dbo].[T_Material_Locations]
(
	[Tag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Material_Locations_ID_include_Tag] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Locations_ID_include_Tag] ON [dbo].[T_Material_Locations]
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Material_Locations] ADD  CONSTRAINT [DF_T_Material_Locations_Freezer_Tag]  DEFAULT ('None') FOR [Freezer_Tag]
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
ALTER TABLE [dbo].[T_Material_Locations]  WITH CHECK ADD  CONSTRAINT [FK_T_Material_Locations_T_Material_Freezers] FOREIGN KEY([Freezer_Tag])
REFERENCES [dbo].[T_Material_Freezers] ([Freezer_Tag])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Material_Locations] CHECK CONSTRAINT [FK_T_Material_Locations_T_Material_Freezers]
GO
ALTER TABLE [dbo].[T_Material_Locations]  WITH CHECK ADD  CONSTRAINT [CK_T_Material_Locations_Status] CHECK  (([Status]='Inactive' OR [Status]='Active'))
GO
ALTER TABLE [dbo].[T_Material_Locations] CHECK CONSTRAINT [CK_T_Material_Locations_Status]
GO
