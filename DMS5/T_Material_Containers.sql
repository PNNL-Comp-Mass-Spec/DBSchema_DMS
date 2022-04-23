/****** Object:  Table [dbo].[T_Material_Containers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Material_Containers](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Tag] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Type] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Barcode] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Location_ID] [int] NOT NULL,
	[Created] [datetime] NOT NULL,
	[Status] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Researcher] [varchar](129) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SortKey]  AS (case when [Tag]='Staging' then (2147483645) when [Tag]='Met_Staging' then (2147483644) when [Tag] like '%Staging%' then (2147483500)+len([Tag]) when [Tag]='na' then (2147483500) when [Tag] like 'MC-[0-9]%' then CONVERT([int],substring([Tag],(4),(1000))) when [Tag] like 'Bin%' then len([Tag]) else ascii(substring([Tag],(1),(1)))*(10000000) end) PERSISTED,
 CONSTRAINT [PK_T_Material_Containers] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Material_Containers] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Material_Containers] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Material_Containers] ON [dbo].[T_Material_Containers]
(
	[Tag] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_Material_Containers_LocationID_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Containers_LocationID_ID] ON [dbo].[T_Material_Containers]
(
	[Location_ID] ASC,
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF

GO
/****** Object:  Index [IX_T_Material_Containers_SortKey] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Containers_SortKey] ON [dbo].[T_Material_Containers]
(
	[SortKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Material_Containers_Status] ******/
CREATE NONCLUSTERED INDEX [IX_T_Material_Containers_Status] ON [dbo].[T_Material_Containers]
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Material_Containers] ADD  CONSTRAINT [DF_T_Material_Containers_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Material_Containers] ADD  CONSTRAINT [DF_T_Material_Containers_Status]  DEFAULT ('Active') FOR [Status]
GO
ALTER TABLE [dbo].[T_Material_Containers]  WITH CHECK ADD  CONSTRAINT [FK_T_Material_Containers_T_Material_Locations] FOREIGN KEY([Location_ID])
REFERENCES [dbo].[T_Material_Locations] ([ID])
GO
ALTER TABLE [dbo].[T_Material_Containers] CHECK CONSTRAINT [FK_T_Material_Containers_T_Material_Locations]
GO
